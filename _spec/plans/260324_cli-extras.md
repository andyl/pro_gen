# Implementation Plan: CLI Extras

**Spec:** `_spec/features/260324_cli-extras.md`
**Generated:** 2026-03-24 (rev 3)

---

## Goal

Extend ProGen's CLI with global archive installation and 3rd party library
support, so users can run ProGen from any directory (not just Mix projects that
depend on it) and can install community-contributed action/validation libraries
via `mix progen.install`. Enable a live-editing workflow where a `path:`
reference to a local pro_gen clone lets you edit actions, recompile, and
immediately run the updated code.

## Target Workflow

This is the end-to-end developer experience the implementation enables:

```bash
# 1. Install the thin CLI archive (one-time)
mix archive.install github andyl/pro_gen_cli

# 2. Install ProGen core globally (one-time)
mix progen.install
#    -> fetches pro_gen + deps into ~/.config/pro_gen/deps/

# 3. Use ProGen from any directory
cd /tmp
mix progen.action.list          # lists all built-in actions
mix progen.action.run "greet" io.echo message="hello"

# 4. For development: clone pro_gen locally and configure as path dep
git clone git@github.com:andyl/pro_gen.git ~/src/pro_gen
cat > ~/.config/pro_gen/config.yml <<EOF
libs:
  - name: pro_gen
    path: /home/you/src/pro_gen
EOF
mix progen.install               # recompiles, symlinks ebin

# 5. Edit-compile-run loop
mix progen.action.edit io.echo   # opens source in $EDITOR
cd ~/src/pro_gen && mix compile  # recompile the path dep
mix progen.action.run "test" io.echo message="hi"  # runs updated code

# 6. Push changes back
cd ~/src/pro_gen && git add -A && git commit -m "Update io.echo"
git push
```

The key insight: for `path:` deps, `mix progen.install` symlinks
`~/.config/pro_gen/deps/pro_gen/ebin` to
`~/src/pro_gen/_build/dev/lib/pro_gen/ebin`. When you `mix compile` in the
clone, the symlink reflects the new beam files immediately. No re-install
needed.

## Scope

### In scope
- **Two-package split**: `pro_gen` (core library) and `pro_gen_cli` (CLI tools)
- Two separate GitHub repos: `andyl/pro_gen` and `andyl/pro_gen_cli`
- Thin Mix archive from `pro_gen_cli` containing only Mix tasks + bootstrap
- `ProGen.CLI.Bootstrap` module that prepends `~/.config/pro_gen/deps/*/ebin`
  to code paths
- `mix progen.install` task that reads config, creates a temp Mix project,
  fetches/compiles all deps, copies/symlinks ebin dirs
- YAML config file parsing for `~/.config/pro_gen/config.yml`
- Config validation with clear error messages
- Cache invalidation (`:persistent_term` clear) after install
- Idempotent installs (skip up-to-date deps); `--force` flag to override
- Partial failure handling with summary
- Symlinks for `path:` deps (live recompile workflow)
- Edit access (`action.edit`, `validate.edit`) restricted to `path:` deps only
- Refactor `Mix.Tasks.Docs.Scripts` into `ProGen.Docs.ScriptGuide` (plain
  module) and remove the `Mix.Task` namespace entirely from `pro_gen`
- Tests for all new modules

### Out of scope
- Lock file or dependency resolution
- Uninstall / upgrade commands (manual delete, re-run install)
- Private GitHub repos or authenticated Hex packages
- Per-project lib configuration (global only)
- Git branch/tag selection for github deps (default branch only)
- TOML config format
- `$XDG_CONFIG_HOME` support (hardcode `~/.config` for v1)
- OTP application startup (actions/validations are pure functions)

## Architecture & Design Decisions

### 1. Two-package split: `pro_gen` vs `pro_gen_cli`

**The problem:** `mix archive.build` bundles all beam files in the project.
If actions and Mix tasks live in the same package, the archive includes the
action modules. When the archive loads, those modules are already in BEAM
memory — and a `path:` dep's versions can't override them (first-loaded wins).

**The solution:** Split into two packages:

| Package | Repo | Contains | Ships as |
|---|---|---|---|
| `pro_gen` | `andyl/pro_gen` | Action/Validate behaviours, registries, built-in actions/validations, Script, Config, AutoCommit, CodeMods, Sys, Env, Util | Hex package or GitHub dep |
| `pro_gen_cli` | `andyl/pro_gen_cli` | Mix tasks, CLI helpers, Bootstrap, GlobalConfig, Installer | Mix archive |

The archive contains **zero** action or validation modules. All "content" is
fetched by `mix progen.install` and loaded at runtime by the bootstrap. A
`path:` dep naturally overrides the default installed version because it's the
only source of those modules.

### 2. Two separate repos (not monorepo)

**Two repos** (`andyl/pro_gen` and `andyl/pro_gen_cli`) rather than a
monorepo with subdirectories or an umbrella project.

**Rationale:**
- `mix archive.install github andyl/pro_gen_cli` just works — it clones the
  repo, finds `mix.exs` at the root, builds, and installs. With a monorepo
  subdirectory, this command would build from the wrong `mix.exs`.
- Independent release cycles: the CLI changes rarely (new task, bug fix), the
  core changes frequently (new actions/validations). Decoupling avoids
  unnecessary archive rebuilds.
- The dependency direction is one-way: `pro_gen_cli` depends on `pro_gen`,
  never the reverse. Clean DAG.
- Each repo has its own `mix.exs`, tests, CI, `CLAUDE.md`.

**Monorepo alternative (considered, not chosen):** A subdirectory layout
(`pro_gen/cli/`) would mean one repo to clone and push, but
`mix archive.install github` wouldn't work without a custom build step. Users
would need to clone and run `cd cli && mix archive.build && mix archive.install`
manually. The two-repo approach trades one extra `git clone` for a smooth
one-liner install.

### 3. Working with Claude Code across two repos

Since the repos are separate, the typical workflow with Claude is:

**Day-to-day (most common):** Work in `pro_gen` only. Adding actions, editing
validations, fixing bugs in core logic. The CLI doesn't change. Run Claude
Code from `~/src/pro_gen/`.

**CLI changes (infrequent):** When adding a new Mix task or modifying the
install/bootstrap logic, work in `pro_gen_cli`. Run Claude Code from
`~/src/pro_gen_cli/`.

**Cross-cutting changes (rare):** When a change to pro_gen's API requires a
corresponding CLI update (e.g., new callback in the Action behaviour that
`action.info` should display):
1. Make the pro_gen change first, push it.
2. Switch to pro_gen_cli, update `mix.exs` dep if needed, make the CLI change.
3. Or run two Claude Code sessions side by side in two terminals.

Each repo gets its own `CLAUDE.md` with project-specific instructions. The
`pro_gen_cli/CLAUDE.md` explains the bootstrap/install architecture and
references `pro_gen` as its upstream dependency.

### 4. What moves where

**Stays in `pro_gen`:**
- `lib/pro_gen/action.ex` — Action behaviour
- `lib/pro_gen/actions.ex` — Action registry
- `lib/pro_gen/validate.ex` — Validate behaviour
- `lib/pro_gen/validations.ex` — Validation registry
- `lib/pro_gen/action/` — all built-in actions
- `lib/pro_gen/validate/` — all built-in validators
- `lib/pro_gen/script.ex` — Script API
- `lib/pro_gen/config.ex` — project-level config (`.progen.yml`)
- `lib/pro_gen/auto_commit.ex` — shared by Script + CLI tasks
- `lib/pro_gen/code_mods/` — AST code modification utilities
- `lib/pro_gen/sys.ex`, `lib/pro_gen/env.ex`, `lib/pro_gen/util.ex`
- All existing tests for the above

**Moves to `pro_gen_cli` (removed from `pro_gen`):**
- `lib/mix/tasks/progen/` — all 10 Mix task modules
- `lib/pro_gen/cli.ex` — shared CLI helpers
- `test/pro_gen/cli_test.exs` — CLI helper tests
- `test/pro_gen/cli/` — all CLI task tests

**Refactored in `pro_gen` (not moved, but changed):**
- `lib/mix/tasks/docs.scripts.ex` — refactored into
  `lib/pro_gen/docs/script_guide.ex` as `ProGen.Docs.ScriptGuide` (plain
  module, not a Mix task). The `lib/mix/` directory is then deleted entirely
  from `pro_gen`.

**New in `pro_gen_cli`:**
- `lib/pro_gen/cli/bootstrap.ex` — code path loading
- `lib/pro_gen/cli/global_config.ex` — `~/.config/pro_gen/config.yml` reader
- `lib/pro_gen/cli/installer.ex` — install orchestration
- `lib/mix/tasks/progen/install.ex` — the install task

### 5. Zero Mix tasks in `pro_gen`

After the split, `pro_gen` has no `lib/mix/` directory at all. The
`docs.scripts` task is refactored into `ProGen.Docs.ScriptGuide.generate/0`,
a plain module with a `generate/0` function. The `mix.exs` alias changes from:

```elixir
# Before
defp aliases do
  [docgen: ["docs.scripts", &reload_and_docs/1]]
end
```

to:

```elixir
# After
defp aliases do
  [docgen: [&generate_script_guide/1, &reload_and_docs/1]]
end

defp generate_script_guide(_) do
  ProGen.Docs.ScriptGuide.generate()
end
```

Users who want CLI access install the archive. Users who use `pro_gen` as a
project dependency call the Elixir API directly (`ProGen.Actions.run/2`, etc.).

### 6. `pro_gen_cli/mix.exs` dependency on `pro_gen`

The `pro_gen_cli` project depends on `pro_gen` at **compile time only** (so
the CLI modules can reference `ProGen.Actions`, `ProGen.AutoCommit`, etc.).
At runtime, the archive does not include `pro_gen`'s modules — the bootstrap
loads them from `~/.config/pro_gen/deps/`.

For local development, use a conditional dep:

```elixir
defp deps do
  pro_gen_opts =
    if File.exists?("../pro_gen/mix.exs"),
      do: [path: "../pro_gen"],
      else: [github: "andyl/pro_gen"]

  [
    {:pro_gen, pro_gen_opts},
    {:yaml_elixir, "~> 2.11"}
  ]
end
```

This is purely a compile-time concern. The config.yml `path:` override
operates at a different layer — it controls what `mix progen.install` fetches
and what the bootstrap loads at runtime. These two layers are independent:
`mix.exs` is for building the archive, `config.yml` is for running it.

### 7. Bootstrap module as gatekeeper

Every Mix task's `run/1` calls `ProGen.CLI.Bootstrap.ensure_loaded!/0` first.
This checks if `ProGen.Actions` is available. If not, it adds ebin paths from
`~/.config/pro_gen/deps/*/ebin`. If still not available, it prints an error
directing users to run `mix progen.install`.

When running inside a Mix project that depends on `pro_gen`, the bootstrap is
a no-op (modules already loaded). This dual-mode behavior is the key design
choice.

### 8. Install via temporary Mix project

`mix progen.install` creates a temporary Mix project with all configured deps
(including `pro_gen` itself), runs `mix deps.get && mix deps.compile`, then
copies or symlinks `_build/dev/lib/*/ebin` to `~/.config/pro_gen/deps/`.

For Hex deps without a version, follow the `Mix.install/2` convention: the
version is required for Hex deps (return a validation error if missing).

### 9. `path:` deps use symlinks

For `path:` deps, `mix progen.install` compiles the path dep in the temp
project, then creates a symlink from `~/.config/pro_gen/deps/<name>/ebin` to
the source project's `_build/dev/lib/<name>/ebin`. This means `mix compile`
in the source project immediately updates the globally visible beam files.
No re-install needed.

### 10. Edit access restricted to `path:` deps

`action.edit` and `validate.edit` are only allowed for modules whose source
file exists on disk. This naturally restricts editing to `path:` deps:

- **`path:` deps** — source code lives on disk at a known location. The
  beam file's embedded source path (via `mod.__info__(:compile)[:source]`)
  points to a real file. `action.edit` opens it in `$EDITOR`.
- **`github:` and `hex:` deps** — only compiled beam files exist in
  `~/.config/pro_gen/deps/<name>/ebin/`. The embedded source path points to
  a temp directory that was cleaned up after install. The file doesn't exist.

Implementation: `action.edit` checks `File.exists?(source_path)`. If the
file doesn't exist, print:
```
Cannot edit "io.echo": source not available.
Only path: dependencies can be edited.
```

`action.cat` can work for any dep by reading source embedded in the beam
file (via `:beam_lib.chunks/2` with `:abstract_code`), but this is a
nice-to-have for a later iteration.

### 11. Namespace conventions

Both packages define modules in the `ProGen` namespace. This is normal in
Elixir (cf. `phoenix` vs `phoenix_html` both using `Phoenix.*`):
- `pro_gen` owns `ProGen.*` excluding `ProGen.CLI.*`
- `pro_gen_cli` owns `ProGen.CLI.*` and `Mix.Tasks.Progen.*`

## Implementation Steps

### Phase 0: Prepare `pro_gen` for the split

1. **Refactor `Mix.Tasks.Docs.Scripts` to `ProGen.Docs.ScriptGuide`**
   - File: create `lib/pro_gen/docs/script_guide.ex`
   - Move the logic from `lib/mix/tasks/docs.scripts.ex` into a plain module
     `ProGen.Docs.ScriptGuide` with a public `generate/0` function.
   - The function does exactly what the Mix task's `run/1` did: reads scripts
     from `scripts/`, generates markdown, writes to `guides/example_scripts.md`.
   - Update `mix.exs` aliases to call the new module directly:
     ```elixir
     defp aliases do
       [docgen: [&generate_script_guide/1, &reload_and_docs/1]]
     end

     defp generate_script_guide(_) do
       ProGen.Docs.ScriptGuide.generate()
     end
     ```
   - Delete `lib/mix/tasks/docs.scripts.ex`.
   - Delete the `lib/mix/tasks/` and `lib/mix/` directories entirely.
   - Verify `mix docgen` still works.
   - Verify all `pro_gen` tests still pass.

2. **Remove CLI modules and tests from `pro_gen`**
   - Delete `lib/pro_gen/cli.ex`
   - Delete `lib/mix/tasks/progen/` (all 10 task files — already gone after
     step 1 deleted `lib/mix/`)
   - Delete `test/pro_gen/cli_test.exs`
   - Delete `test/pro_gen/cli/` (action_tasks_test, validate_tasks_test,
     command_puts_test, auto_commit_test)
   - Verify remaining `pro_gen` tests still pass.
   - Commit: "Remove CLI modules in preparation for pro_gen_cli split"

### Phase 1: Create the `pro_gen_cli` repo

3. **Create the `pro_gen_cli` repo and project skeleton**
   - Create a new GitHub repo `andyl/pro_gen_cli`
   - Initialize with `mix new pro_gen_cli`
   - File: `pro_gen_cli/mix.exs`
     - `app: :pro_gen_cli`
     - `version: "0.0.1"`
     - `elixir: "~> 1.19"`
     - Dependencies (with conditional `pro_gen` reference):
       ```elixir
       defp deps do
         pro_gen_opts =
           if File.exists?("../pro_gen/mix.exs"),
             do: [path: "../pro_gen"],
             else: [github: "andyl/pro_gen"]

         [
           {:pro_gen, pro_gen_opts},
           {:yaml_elixir, "~> 2.11"}
         ]
       end
       ```
     - `elixirc_paths: ["lib", "test/support"]` for test env
   - File: `pro_gen_cli/CLAUDE.md` — document the project structure,
     relationship to `pro_gen`, and the bootstrap/install architecture
   - File: `pro_gen_cli/.formatter.exs`

4. **Add existing CLI modules to `pro_gen_cli`**
   - Add `lib/pro_gen/cli.ex` (shared CLI helpers, from `pro_gen`'s git history)
   - Add `lib/mix/tasks/progen/action/list.ex`, `info.ex`, `run.ex`, `cat.ex`
   - Add `lib/mix/tasks/progen/validate/list.ex`, `info.ex`, `run.ex`, `cat.ex`
   - Add `lib/mix/tasks/progen/command/run.ex`
   - Add `lib/mix/tasks/progen/puts.ex`
   - Add `test/pro_gen/cli_test.exs`
   - Add `test/pro_gen/cli/action_tasks_test.exs`,
     `validate_tasks_test.exs`, `command_puts_test.exs`,
     `auto_commit_test.exs`
   - Copy any needed test support fixtures from `pro_gen/test/support/`
   - Verify `pro_gen_cli` compiles and tests pass.

### Phase 2: Global Config Module

5. **Create `ProGen.CLI.GlobalConfig` module**
   - File: `pro_gen_cli/lib/pro_gen/cli/global_config.ex`
   - Reads `~/.config/pro_gen/config.yml` (or `.yaml`).
   - Public functions:
     - `config_dir/0` — returns `Path.expand("~/.config/pro_gen")`
     - `deps_dir/0` — returns `Path.join(config_dir(), "deps")`
     - `config_path/0` — returns the path to the config file (checks `.yml`
       then `.yaml`, returns nil if neither exists)
     - `read/0` — parses YAML, returns `{:ok, config_map}` or
       `{:error, message}`. If file doesn't exist, returns
       `{:ok, %{libs: []}}`.
     - `validate/1` — validates the parsed YAML structure: `libs:` must be a
       list, each entry needs `name:` (string) and exactly one source key
       (`path:`, `github:`, or `hex:` with required `version:`). Returns
       `{:ok, libs}` or `{:error, message}`.
   - The `libs` return value is a list of maps:
     ```elixir
     [
       %{name: "my_actions", source: {:path, "/home/user/projects/my_actions"}},
       %{name: "team_utils", source: {:github, "myorg/pro_gen_utils"}},
       %{name: "community_pack", source: {:hex, "pro_gen_community", "~> 0.2"}}
     ]
     ```

6. **Write tests for `ProGen.CLI.GlobalConfig`**
   - File: `pro_gen_cli/test/pro_gen/cli/global_config_test.exs`
   - Test `read/0` with: valid YAML, missing file, empty file, malformed YAML.
   - Test `validate/1` with: valid libs of each source type, missing `name:`,
     missing source key, multiple source keys, non-list `libs:`, hex dep
     without version (error).
   - Use temp dirs for config files to avoid touching real `~/.config`.
   - Override `config_dir/0` in tests via application env or a test helper.

### Phase 3: Bootstrap Module

7. **Create `ProGen.CLI.Bootstrap` module**
   - File: `pro_gen_cli/lib/pro_gen/cli/bootstrap.ex`
   - Public functions:
     - `ensure_loaded!/0` — Check `Code.ensure_loaded?(ProGen.Actions)`.
       If yes, return `:ok`. If no, call `load_deps/0`. If still not loaded,
       raise with: `"ProGen is not installed. Run: mix progen.install"`.
     - `load_deps/0` — Glob `ProGen.CLI.GlobalConfig.deps_dir()/*/ebin`,
       call `Code.prepend_path/1` for each dir found. Returns `:ok`.
   - This module cannot depend on `ProGen.Actions` (may not be loaded yet).
     It can depend on `ProGen.CLI.GlobalConfig` (ships in the archive).

8. **Write tests for `ProGen.CLI.Bootstrap`**
   - File: `pro_gen_cli/test/pro_gen/cli/bootstrap_test.exs`
   - Test `load_deps/0` with a temp deps directory containing mock ebin dirs.
     Verify paths are added to `:code.get_path/0`.
   - Test `ensure_loaded!/0` when modules are already available (no-op).
   - Test `ensure_loaded!/0` error message when deps dir is empty/missing.

### Phase 4: Installer Module

9. **Create `ProGen.CLI.Installer` module**
   - File: `pro_gen_cli/lib/pro_gen/cli/installer.ex`
   - Public functions:
     - `install(libs, opts)` — Takes the list of lib configs from GlobalConfig.
       `opts` supports `force: true` to re-install everything.
       Returns `{:ok, summary}` or `{:error, summary}` where summary is
       `%{installed: [...], skipped: [...], failed: [...]}`.
   - Internal workflow:
     1. Create temp dir, ensure `deps_dir()` exists via `File.mkdir_p!/1`.
     2. Build `mix.exs` for temp project with ProGen + all configured libs
        as dependencies:
        - Always include: `{:pro_gen, github: "andyl/pro_gen"}`
        - `{:path, p}` -> `{name_atom, path: p}`
        - `{:github, repo}` -> `{name_atom, github: repo}`
        - `{:hex, pkg, vsn}` -> `{name_atom, vsn}`
     3. If a lib named `"pro_gen"` appears with a `path:` source, it
        **replaces** the default github reference. This is how the dev
        workflow overrides the installed ProGen.
     4. Write `mix.exs` to temp dir, run `mix deps.get`, run
        `mix deps.compile --force` (via `System.cmd/3` with `cd: temp_dir`).
     5. For each `_build/dev/lib/*/ebin` in the temp project:
        - Non-path deps: `File.cp_r!/2` to `deps_dir/<name>/ebin/`
        - Path deps: `File.ln_s!/2` from `deps_dir/<name>/ebin` to the
          source project's `_build/dev/lib/<name>/ebin`
     6. Wrap each dep in try/rescue, accumulate results into summary.
     7. Clean up temp dir in an `after` block.
   - Private helpers:
     - `build_temp_mixfile/1` — generates mix.exs content string
     - `run_mix/2` — runs a mix command in the temp dir
     - `copy_or_link_ebin/3` — copies or symlinks based on source type
     - `already_installed?/2` — checks if ebin dir exists and is current
       (skip when not `force:`)

10. **Write tests for `ProGen.CLI.Installer`**
    - File: `pro_gen_cli/test/pro_gen/cli/installer_test.exs`
    - Unit test `build_temp_mixfile/1` for each source type.
    - Unit test `already_installed?/2` with temp dirs.
    - Integration test with a `path:` dep: create a minimal Mix project in
      temp dir that defines `ProGen.Action.Test.External`, install it, verify
      the ebin symlink points to the right place.
    - Test `force: true` re-installs even when already present.
    - Test the pro_gen path override: when libs include
      `%{name: "pro_gen", source: {:path, "..."}}`, it replaces the github ref.

### Phase 5: Install Mix Task

11. **Create `mix progen.install` task**
    - File: `pro_gen_cli/lib/mix/tasks/progen/install.ex`
    - Module: `Mix.Tasks.Progen.Install`
    - `@shortdoc "Install ProGen and configured libraries globally"`
    - Supports `--force` flag.
    - `run/1` workflow:
      1. Parse args for `--force` flag.
      2. Print "Reading config..."
      3. Call `GlobalConfig.read/0`. On error, `Mix.raise/1`.
      4. Call `GlobalConfig.validate/1` on the result. On error, `Mix.raise/1`.
      5. Print "Installing <N> libraries..."
      6. Call `Installer.install(libs, force: force)`.
      7. Call `Bootstrap.load_deps/0` to add new ebin paths.
      8. Clear `:persistent_term` caches:
         `{ProGen.Actions, :actions_list}`, `{ProGen.Actions, :actions_map}`,
         `{ProGen.Validations, :validations_list}`,
         `{ProGen.Validations, :validations_map}`.
      9. Print summary.
      10. If any failures, `Mix.raise/1` for non-zero exit.
    - Note: This task does NOT call `Bootstrap.ensure_loaded!/0` — it is the
      task that creates the deps.

12. **Write tests for `mix progen.install`**
    - File: `pro_gen_cli/test/pro_gen/cli/install_test.exs`
    - Test with no config file: installs ProGen only.
    - Test with invalid config: clear error.
    - Test `--force` flag is passed through.
    - Test cache invalidation: verify persistent_term keys are cleared.
    - Test summary output.

### Phase 6: Bootstrap Integration and Edit Restriction

13. **Add bootstrap call to all existing Mix tasks**
    - Files: all 10 task files in `pro_gen_cli/lib/mix/tasks/progen/`
    - Add `ProGen.CLI.Bootstrap.ensure_loaded!()` as the first line of each
      `run/1`, before `Mix.Task.run("app.start")`.
    - When running inside a Mix project that depends on `pro_gen`, modules
      are already loaded, so this is a fast no-op.

14. **Add `action.edit` and `validate.edit` tasks with path-dep restriction**
    - File: `pro_gen_cli/lib/mix/tasks/progen/action/edit.ex`
    - File: `pro_gen_cli/lib/mix/tasks/progen/validate/edit.ex`
    - These were deferred from CLI Core. Now implement them with the
      `path:` restriction:
      1. Resolve name, look up module.
      2. Get source path via `mod.__info__(:compile)[:source]`.
      3. Check `File.exists?(source_path)`.
      4. If source exists: open in `$EDITOR` (default `"vim"`).
      5. If source doesn't exist: print error:
         `Cannot edit "<name>": source not available. Only path: dependencies can be edited.`
    - Write tests for both the success and restriction paths.

15. **Verify all tests pass**
    - Run the full `pro_gen_cli` test suite.
    - Run the full `pro_gen` test suite (confirm nothing broke from Phase 0).

### Phase 7: Archive Build and Test

16. **Configure `pro_gen_cli/mix.exs` for archive building**
    - The default `mix archive.build` from `pro_gen_cli` will include only
      `pro_gen_cli`'s own beam files — the Mix tasks, CLI helpers, Bootstrap,
      GlobalConfig, and Installer. It will NOT include `pro_gen`'s modules
      (actions, validations, etc.) because those are a dep, and archive.build
      excludes deps.
    - No special configuration needed — this is the natural behavior of
      `mix archive.build`.
    - Verify: `mix archive.build` produces a `.ez` file, inspect its contents
      to confirm no `ProGen.Action.*` or `ProGen.Validate.*` modules.

17. **End-to-end manual test**
    - Build and install archive:
      ```bash
      cd pro_gen_cli && mix archive.build && mix archive.install
      ```
    - From `/tmp`: `mix progen.action.list` -> bootstrap error directing
      user to run `mix progen.install`
    - `mix progen.install` -> fetches pro_gen + deps from github
    - `mix progen.action.list` -> shows all built-in actions
    - Configure a `path:` dep to local pro_gen clone, re-run install
    - Verify symlink exists and points to the right ebin
    - Test edit-compile-run loop:
      - `mix progen.action.edit io.echo` -> opens source in editor
      - Edit action, `mix compile` in pro_gen clone
      - `mix progen.action.run "test" io.echo message="hi"` -> runs new code
    - Test edit restriction:
      - Remove `path:` config, re-install (github dep)
      - `mix progen.action.edit io.echo` -> prints "source not available" error

## Dependencies & Ordering

- **Phase 0 (prepare pro_gen) must come first** — refactor docs.scripts,
  remove CLI modules from pro_gen.
- **Phase 1 (create pro_gen_cli) depends on Phase 0** — needs the modules
  removed from pro_gen to be added to pro_gen_cli.
- **Phase 2 (GlobalConfig) must come before Phases 3, 4, 5** — Bootstrap
  and Installer depend on `config_dir/0` and `deps_dir/0`.
- **Phases 3 (Bootstrap) and 4 (Installer) are independent** — can be
  developed in parallel after Phase 2.
- **Phase 5 (Install task) depends on Phases 2-4** — orchestrates them.
- **Phase 6 (Bootstrap integration + edit) depends on Phases 3 and 1.**
- **Phase 7 (Archive build) depends on all previous phases.**

## Edge Cases & Risks

- **No config file:** `mix progen.install` with no config installs only
  ProGen itself (empty libs list). This is the happy path for first-time
  users.

- **`path:` dep named `pro_gen`:** When the config includes
  `{name: "pro_gen", path: "/home/user/src/pro_gen"}`, the installer must
  replace the default `{:pro_gen, github: "andyl/pro_gen"}` dep with
  `{:pro_gen, path: "/home/user/src/pro_gen"}`. Special case in the dep
  list builder.

- **Symlink on Windows:** `File.ln_s/2` may fail. Fall back to copy with a
  warning. Low risk since Elixir dev on Windows typically uses WSL.

- **Temp project cleanup:** Use `File.rm_rf!/1` in an `after` block to
  ensure the temp Mix project is removed even on failure.

- **Cache invalidation timing:** After install, must call
  `Bootstrap.load_deps/0` first (add ebin paths), then clear
  `:persistent_term` (so re-scan finds new modules). Order matters.

- **Partial compilation failure:** Check which ebin dirs were actually
  produced rather than assuming all deps compiled. Log failures, continue
  with successes.

- **Archive doesn't include deps:** This is the desired behavior — the thin
  archive has only CLI modules. But it means `pro_gen_cli`'s compile-time dep
  on `pro_gen` is only used during development/compilation, not at runtime.
  The bootstrap fills this in at runtime.

- **Duplicate modules if both project dep and global install exist:** When
  running in a Mix project that depends on `pro_gen`, the project's version
  takes priority (loaded by `app.start`). The bootstrap's
  `Code.prepend_path` calls are effectively ignored because the modules are
  already loaded. This is correct behavior.

- **Config `.yml` vs `.yaml`:** Support both, check `.yml` first (matching
  the project-level `ProGen.Config` pattern).

- **Moving files between repos:** Git history for moved files is lost.
  Add a note in commit messages referencing the original repo and commits.

- **Edit restriction for non-path deps:** The source path embedded in beam
  files for github/hex deps points to the temp project directory (deleted
  after install). `File.exists?/1` returns false, so the edit is blocked
  with a clear message.

## Testing Strategy

- **Unit tests for `ProGen.Docs.ScriptGuide`:** Verify `generate/0` produces
  the expected markdown output. Run in `pro_gen` repo.

- **Unit tests for `ProGen.CLI.GlobalConfig`:** Test YAML parsing and
  validation with fixture YAML strings written to temp files. Cover all
  source types, missing fields, and edge cases.

- **Unit tests for `ProGen.CLI.Bootstrap`:** Create temp deps directories
  with mock ebin dirs. Verify code paths are prepended. Test the no-op case.

- **Unit tests for `ProGen.CLI.Installer`:** Test mixfile generation. Test
  `already_installed?/2`. Integration test with `path:` dep using a local
  fixture Mix project.

- **Integration test for `mix progen.install`:** Full end-to-end with temp
  config dir and `path:` dep. Verify ebin symlink and action discovery.

- **Edit restriction tests:** Test `action.edit` with a path dep (source
  exists) succeeds. Test with a non-path dep (source doesn't exist) prints
  the restriction message.

- **Regression tests:** Run both `pro_gen` and `pro_gen_cli` test suites
  after the split to ensure nothing broke.

- **Manual E2E test:** Build archive, install, run from outside project,
  test full path-dep edit-compile-run workflow.

## All Resolved Questions

- [x] **Two repos or monorepo?** Two repos. `mix archive.install github
  andyl/pro_gen_cli` works out of the box.

- [x] **Hex deps without version?** Require version (match `Mix.install`
  behavior). Return validation error if missing.

- [x] **`--force` flag?** Yes, supported.

- [x] **`path:` dep compilation?** Recompile in temp project, then symlink
  ebin to source's `_build/dev/lib/<name>/ebin`.

- [x] **OTP app startup?** Not needed. Actions and validations are pure
  functions.

- [x] **`$XDG_CONFIG_HOME`?** Hardcode `~/.config` for v1.

- [x] **Archive = separate project?** Yes. Two-package split enables the
  `path:` override workflow.

- [x] **`pro_gen_cli/mix.exs` dep on `pro_gen`?** Use
  `if File.exists?("../pro_gen/mix.exs")` for dev vs CI. Config.yml does
  not need to influence `mix.exs` — they operate at different layers
  (compile-time vs runtime). The config.yml `path:` override controls what
  `mix progen.install` fetches and what the bootstrap loads, not how the
  archive is compiled.

- [x] **Edit access?** Restricted to `path:` deps only. Check if source
  file exists on disk. github/hex deps get a clear error message.

- [x] **`docs.scripts` task?** Refactored to `ProGen.Docs.ScriptGuide`
  (plain module). The `lib/mix/` directory is removed entirely from
  `pro_gen`. Zero Mix tasks remain in the core library.

- [x] **Mix tasks in `pro_gen` as project dep?** Remove entirely. Users get
  CLI via the archive. Programmatic access via `ProGen.Actions.run/2`, etc.
