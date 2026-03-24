# Implementation Plan: CLI Extras

**Spec:** `_spec/features/260324_cli-extras.md`
**Generated:** 2026-03-24

---

## Goal

Extend ProGen's CLI with global archive installation and 3rd party library
support, so users can run ProGen from any directory (not just Mix projects that
depend on it) and can install community-contributed action/validation libraries
via `mix progen.install`.

## Scope

### In scope
- Thin Mix archive containing the 10 existing Mix task modules + a bootstrap module
- `ProGen.CLI.Bootstrap` module that prepends `~/.config/pro_gen/deps/*/ebin` to code paths
- `mix progen.install` task that reads `~/.config/pro_gen/config.yml`, creates
  a temp Mix project, fetches/compiles all deps, and copies ebin dirs to
  `~/.config/pro_gen/deps/`
- YAML config file parsing for `~/.config/pro_gen/config.yml` (libs with `path:`, `github:`, `hex:` sources)
- Config validation with clear error messages
- Cache invalidation (`:persistent_term` clear) after install
- Idempotent installs (skip up-to-date deps)
- Partial failure handling with summary
- Symlinks for `path:` deps
- Tests for all new modules

### Out of scope
- Lock file or dependency resolution
- Uninstall / upgrade commands
- Private GitHub repos or authenticated Hex packages
- Per-project lib configuration (global only)
- Git branch/tag selection for github deps (default branch only)
- TOML config format

## Architecture & Design Decisions

### 1. Thin archive vs. fat archive

The archive includes **only** the Mix task modules and the bootstrap module —
not ProGen's core libraries. This keeps the archive small and avoids version
conflicts. ProGen's actual code is fetched by `mix progen.install` into
`~/.config/pro_gen/deps/` and loaded at runtime via `Code.prepend_path/1`.

**Rationale:** A fat archive would embed all of ProGen and its deps (igniter,
sourceror, nimble_options, etc.), making it huge and hard to update. The thin
approach means `mix archive.install github andyl/pro_gen` is fast, and `mix
progen.install` handles the heavy lifting.

### 2. Bootstrap module as gatekeeper

Every Mix task's `run/1` calls `ProGen.CLI.Bootstrap.ensure_loaded!/0` early.
This function checks if `ProGen.Actions` is available. If not, it loads ebin
paths from `~/.config/pro_gen/deps/*/ebin`. If still not available, it raises
with a message directing users to run `mix progen.install`.

**Rationale:** When running inside a Mix project that depends on ProGen, the
bootstrap is a no-op (modules already loaded). When running globally from the
archive, bootstrap fills in the missing code paths. This dual-mode behavior is
the key design choice.

### 3. Install via temporary Mix project

`mix progen.install` creates a temporary Mix project with all configured deps
(including ProGen itself), runs `mix deps.get && mix deps.compile`, then copies
the `_build/*/lib/*/ebin` directories to `~/.config/pro_gen/deps/`. This
leverages Mix's existing dependency resolution for Hex and Git deps.

**Rationale:** Re-implementing Hex/Git fetching and compilation would be
duplicating Mix's robust infrastructure. A temp project is simple and correct.

### 4. Config file location and format

`~/.config/pro_gen/config.yml` follows the XDG Base Directory Specification
(`$XDG_CONFIG_HOME` or `~/.config`). YAML is already a dependency
(`yaml_elixir`) and is consistent with the existing `.progen.yml` project
config pattern.

### 5. `path:` deps use symlinks

Local path deps are symlinked (not copied) so changes are immediately
reflected without re-running install. This matches how Mix handles `path:`
deps in `mix.exs`.

### 6. Separation of concerns

- `ProGen.CLI.Bootstrap` — code path loading logic
- `ProGen.CLI.GlobalConfig` — reading/validating `~/.config/pro_gen/config.yml`
- `ProGen.CLI.Installer` — the install orchestration logic
- `Mix.Tasks.Progen.Install` — thin Mix task wrapper

This keeps each module focused and testable independently.

## Implementation Steps

### Phase 1: Global Config Module

1. **Create `ProGen.CLI.GlobalConfig` module**
   - File: `lib/pro_gen/cli/global_config.ex`
   - Reads `~/.config/pro_gen/config.yml` (or `.yaml`). Respects
     `$XDG_CONFIG_HOME` if set, else defaults to `~/.config`.
   - Public functions:
     - `config_dir/0` — returns `~/.config/pro_gen` (or `$XDG_CONFIG_HOME/pro_gen`)
     - `deps_dir/0` — returns `config_dir()/deps`
     - `read/0` — parses YAML, returns `{:ok, config_map}` or `{:error, message}`.
       If file doesn't exist, returns `{:ok, %{libs: []}}` (empty libs list).
     - `validate/1` — validates the parsed YAML structure: `libs:` must be a
       list, each entry needs `name:` (string) and exactly one of `path:`,
       `github:`, or `hex:` (with optional `version:`). Returns `{:ok, libs}`
       or `{:error, message}`.
   - The `libs` return value is a list of maps like:
     ```elixir
     [
       %{name: "my_actions", source: {:path, "/home/user/projects/my_actions"}},
       %{name: "team_utils", source: {:github, "myorg/pro_gen_utils"}},
       %{name: "community_pack", source: {:hex, "pro_gen_community", "~> 0.2"}}
     ]
     ```

2. **Write tests for `ProGen.CLI.GlobalConfig`**
   - File: `test/pro_gen/cli/global_config_test.exs`
   - Test `read/0` with valid YAML, missing file, empty file, and malformed YAML.
   - Test `validate/1` with: valid libs, missing `name:`, missing source key,
     multiple source keys, non-list `libs:`, invalid source types.
   - Use temp dirs for config files to avoid touching the real `~/.config`.

### Phase 2: Bootstrap Module

3. **Create `ProGen.CLI.Bootstrap` module**
   - File: `lib/pro_gen/cli/bootstrap.ex`
   - Public functions:
     - `ensure_loaded!/0` — Check if `Code.ensure_loaded?(ProGen.Actions)`.
       If yes, return `:ok`. If no, call `load_deps/0`. If still not loaded,
       raise with: `"ProGen is not installed. Run: mix progen.install"`.
     - `load_deps/0` — Read all subdirectories of
       `ProGen.CLI.GlobalConfig.deps_dir()`, look for `ebin` subdirectory in
       each, call `Code.prepend_path/1` for each ebin dir found. Returns `:ok`.
   - Details: This module must be self-contained — it cannot depend on
     `ProGen.Actions` (which may not be loaded yet). It can depend on
     `ProGen.CLI.GlobalConfig` because that module ships in the archive.

4. **Write tests for `ProGen.CLI.Bootstrap`**
   - File: `test/pro_gen/cli/bootstrap_test.exs`
   - Test `load_deps/0` with a temp deps directory containing mock ebin dirs.
     Verify `Code.prepend_path/1` was called (check `:code.get_path/0`).
   - Test `ensure_loaded!/0` when modules are already available (no-op case).
   - Test `ensure_loaded!/0` error message when deps dir is empty.

### Phase 3: Installer Module

5. **Create `ProGen.CLI.Installer` module**
   - File: `lib/pro_gen/cli/installer.ex`
   - Public function:
     - `install/1` — Takes the list of lib configs from `GlobalConfig`. Returns
       `{:ok, summary}` or `{:error, summary}` where summary has `:installed`,
       `:skipped`, `:failed` lists.
   - Internal workflow:
     1. Ensure `config_dir/deps` directory exists (`File.mkdir_p!/1`).
     2. Build a `mix.exs` for a temporary project that lists ProGen + all
        configured libs as dependencies.
     3. Convert lib configs to Mix dep tuples:
        - `{:path, p}` → `{name_atom, path: p}`
        - `{:github, repo}` → `{name_atom, github: repo}`
        - `{:hex, pkg, vsn}` → `{name_atom, vsn}` or `{name_atom, "~> 0.1"}`
          if no version given
     4. Always include ProGen itself: `{:pro_gen, github: "andyl/pro_gen"}`.
     5. Write `mix.exs` to temp dir, run `mix deps.get`, run `mix deps.compile`.
     6. Copy each `_build/dev/lib/*/ebin` directory to
        `~/.config/pro_gen/deps/<lib>/ebin/`.
     7. For `path:` deps, create a symlink from
        `~/.config/pro_gen/deps/<name>/ebin` to the source's `_build/dev/lib/<name>/ebin`
        (or to the path's own ebin if it's already compiled).
     8. Handle partial failures: wrap each dep copy in a try/rescue, accumulate
        successes and failures.
   - Private helpers:
     - `build_temp_mixfile/1` — generates the mix.exs content string
     - `run_mix_command/2` — runs a mix command in the temp dir via `System.cmd/3`
     - `copy_ebin_dirs/2` — copies ebin directories from temp build to deps dir
     - `already_installed?/2` — checks if a dep is already present and up-to-date

6. **Write tests for `ProGen.CLI.Installer`**
   - File: `test/pro_gen/cli/installer_test.exs`
   - Test `build_temp_mixfile/1` generates valid mix.exs content for different
     source types.
   - Test `already_installed?/2` returns true when ebin dir exists.
   - Integration-level tests are harder (require network). Test with `path:`
     deps pointing to a local fixture project (create a minimal Mix project
     in the test that defines a `ProGen.Action.Test.FromLib` module).
   - Test idempotent behavior: install twice, second run should skip.

### Phase 4: Install Mix Task

7. **Create `mix progen.install` task**
   - File: `lib/mix/tasks/progen/install.ex`
   - Module: `Mix.Tasks.Progen.Install`
   - `@shortdoc "Install ProGen and configured libraries globally"`
   - `run/1` workflow:
     1. Print "Reading config..."
     2. Call `ProGen.CLI.GlobalConfig.read/0`. On error, `Mix.raise/1`.
     3. Call `ProGen.CLI.GlobalConfig.validate/1`. On error, `Mix.raise/1`.
     4. Print "Installing N libraries..."
     5. Call `ProGen.CLI.Installer.install/1`.
     6. Clear `:persistent_term` caches for `ProGen.Actions` and
        `ProGen.Validations` registries (keys:
        `{ProGen.Actions, :actions_list}`, `{ProGen.Actions, :actions_map}`,
        `{ProGen.Validations, :validations_list}`,
        `{ProGen.Validations, :validations_map}`).
     7. Print summary: installed, skipped, failed counts.
     8. If any failures, exit with non-zero via `Mix.raise/1`.
   - Note: This task does NOT call `Bootstrap.ensure_loaded!/0` — it's the
     task that _creates_ the deps. The bootstrap checks the existing ones.

8. **Write tests for `mix progen.install`**
   - File: `test/pro_gen/cli/install_test.exs`
   - Test with no config file: installs ProGen only.
   - Test with invalid config: gets clear error.
   - Test cache invalidation: verify persistent_term keys are cleared.
   - Test summary output format.

### Phase 5: Integrate Bootstrap into Existing Tasks

9. **Add bootstrap call to all existing Mix tasks**
   - Files: all 10 files under `lib/mix/tasks/progen/`
   - Add `ProGen.CLI.Bootstrap.ensure_loaded!()` as the first line of each
     `run/1` function, before `Mix.Task.run("app.start")`.
   - Ordering matters: bootstrap must run first to add code paths, then
     `app.start` loads the application.
   - When running as a project dependency, `ProGen.Actions` is already loaded,
     so `ensure_loaded!/0` is a fast no-op.

10. **Update existing Mix task tests**
    - Files: `test/pro_gen/cli/action_tasks_test.exs`,
      `test/pro_gen/cli/validate_tasks_test.exs`,
      `test/pro_gen/cli/command_puts_test.exs`
    - Verify all existing tests still pass after adding bootstrap calls.
      Since tests run inside the project (modules already loaded), bootstrap
      should be a no-op.

### Phase 6: Archive Configuration

11. **Configure mix.exs for archive building**
    - File: `mix.exs`
    - Add an `escript` or archive-related config. For Mix archives, the key
      items are:
      - Ensure the archive only includes the Mix task modules and
        `ProGen.CLI.Bootstrap` + `ProGen.CLI.GlobalConfig`.
      - Add `def archive` function or configure `archives` in `project/0` if
        needed.
    - Actually, Mix archives are built with `mix archive.build`. The archive
      includes all compiled beam files. To make it thin, we need to ensure the
      archive only ships the minimal set. One approach:
      - Create a separate Mix project (`pro_gen_archive`) that depends on
        ProGen but only compiles the task modules and bootstrap. **OR**
      - Use `mix archive.build --elixir-paths lib/mix/tasks,lib/pro_gen/cli`
        (if supported) to limit what's included.
      - The simplest approach: keep all modules in the archive (they'll fail
        gracefully until bootstrap loads the deps). The archive is still
        small because the heavy deps (igniter, sourceror) aren't included —
        they're fetched by `mix progen.install`.
    - **Decision:** For v1, build the archive from the main project. The
      archive will include all of ProGen's own modules but NOT its deps. When
      running globally, the modules that depend on igniter/sourceror will fail
      to load until `mix progen.install` pulls them in. The Mix task modules
      and bootstrap module have no external deps so they work immediately.
    - Add a note in `mix.exs` or a separate `archive/` directory if a separate
      project is needed.

12. **Test archive build**
    - Manual verification: run `mix archive.build` and inspect the `.ez` file.
    - Verify that `mix archive.install` from the built archive works.
    - Verify `mix progen.action.list` works after install (with deps loaded).

### Phase 7: Documentation and Polish

13. **Add `@moduledoc` and `@shortdoc` to all new modules**
    - Files: all new files from steps 1-7
    - Ensure all public functions have `@doc` strings.

14. **Test end-to-end flow**
    - Manual test script:
      1. `mix archive.build && mix archive.install`
      2. `cd /tmp && mix progen.action.list` → should get bootstrap error
      3. `mix progen.install` → installs ProGen globally
      4. `mix progen.action.list` → shows all actions
      5. Create a config with a path dep, re-run install, verify new actions
         appear.

## Dependencies & Ordering

- **Phase 1 (GlobalConfig) must come first** — the Installer and Bootstrap
  both depend on it for `config_dir/0`, `deps_dir/0`, and config parsing.
- **Phase 2 (Bootstrap) depends on Phase 1** — uses `GlobalConfig.deps_dir/0`.
- **Phase 3 (Installer) depends on Phase 1** — uses GlobalConfig for config
  parsing and directory paths.
- **Phase 4 (Install task) depends on Phases 1-3** — orchestrates
  GlobalConfig + Installer + cache clearing.
- **Phase 5 (Bootstrap integration) depends on Phase 2** — adds bootstrap
  calls to existing tasks.
- **Phase 6 (Archive config) depends on Phases 1-5** — needs all code in
  place before building the archive.
- **Phases 2 and 3 are independent of each other** — can be developed in
  parallel after Phase 1.

## Edge Cases & Risks

- **No config file:** `mix progen.install` with no
  `~/.config/pro_gen/config.yml` should install ProGen itself only (empty libs
  list). This is the happy path for first-time users.

- **`$XDG_CONFIG_HOME` variations:** Must respect `$XDG_CONFIG_HOME` if set
  (some Linux distros set it to non-standard paths). Fall back to
  `~/.config`.

- **Symlink on Windows:** Windows doesn't support Unix symlinks natively.
  `File.ln_s/2` may fail. Mitigation: fall back to copy on `:enotsup` error,
  or document that `path:` deps require Unix/macOS. Since Elixir development
  on Windows typically uses WSL, this is low risk.

- **Concurrent installs:** Two `mix progen.install` runs at the same time
  could race on the deps directory. Mitigation: use a lockfile
  (`~/.config/pro_gen/.installing.lock`) or document as unsupported. For v1,
  document as unsupported.

- **Temp project cleanup:** The temporary Mix project created during install
  should be cleaned up after completion. Use `File.rm_rf!/1` in an `after`
  block to ensure cleanup even on failure.

- **Mix availability in archive context:** When running as an archive, `Mix`
  is available (archives are loaded by Mix). However, `Mix.Task.run("app.start")`
  may not work as expected when there's no Mix project. The bootstrap must
  handle this gracefully — only call `app.start` when inside a project.

- **Cache invalidation timing:** After `mix progen.install` clears
  `:persistent_term`, the next call to `list_actions/0` will re-scan. But
  the newly installed ebin paths must already be on the code path for the
  new modules to be discovered. The install task should call
  `Bootstrap.load_deps/0` after copying ebins and before clearing caches.

- **Partial compilation failure:** If one lib fails to compile in the temp
  project, Mix may still compile others. The installer should check which
  ebin dirs were actually produced rather than assuming all succeeded.

- **Hex dep without version:** The spec says `version:` is optional for hex
  deps. Without it, we need a sensible default. Using `">= 0.0.0"` (any
  version) is the most permissive. Alternatively, require version for hex deps
  and return a validation error if missing.

- **Config with `.yml` vs `.yaml` extension:** Support both, check `.yml`
  first (matching the project-level `ProGen.Config` pattern).

## Testing Strategy

- **Unit tests for `ProGen.CLI.GlobalConfig`:** Test YAML parsing and
  validation with fixture YAML strings written to temp files. Cover all
  source types, missing fields, and edge cases.

- **Unit tests for `ProGen.CLI.Bootstrap`:** Create temp deps directories
  with mock ebin dirs. Verify code paths are prepended. Verify the no-op
  case when modules are already loaded.

- **Unit tests for `ProGen.CLI.Installer`:** Test mixfile generation
  (string output). Test `already_installed?/2` with temp dirs. For
  integration tests, create a minimal local Mix project with a single
  `ProGen.Action.Test.External` module and install it via `path:`.

- **Integration test for `mix progen.install`:** Full end-to-end with a
  temp config dir, a `path:` dep pointing to a fixture project. Verify
  the ebin is copied/symlinked and the action is discoverable after
  cache clear + re-scan.

- **Regression tests:** Run all existing test suites to ensure bootstrap
  integration doesn't break anything.

- **Manual testing:** Build and install the archive, run tasks from
  outside a Mix project, test the full install flow.

## Open Questions

- [x] Should the archive be a separate Mix project (e.g., `pro_gen_archive/`)
  to ensure only task modules are included? Or is building from the main
  project with all modules acceptable for v1? Answer: when I use "mix
  progen.action.edit <module_spec>", I'd like to be able to edit the source
  code of the action, then compile and run.  Probably this would make sense if
  I used a :path reference to the pro_gen repo, and the :path reference
  over-rode any internal references.  Is this possible???  If so it could be
  great because with a path reference, I could update my actions and
  validations in the course of doing business, then push my changes back to the
  main repo.  Does this make sense?  Maybe the ProGen cli needs to be a
  seperate package from ProGen actions and validations.  Let's discuss before
  editing.

- [x] For `hex:` deps without a `version:`, should we default to `">= 0.0.0"`
  or require the user to specify a version?  Answer: however it's done with
  Mix.install, let's do it that way.

- [x] Should `mix progen.install` support a `--force` flag to re-install
  everything regardless of current state?  Answer: YES

- [x] How should `path:` deps handle compilation? Should we compile them in
  the temp project (treating them like any other dep) or expect them to be
  pre-compiled and just symlink their ebin?  Answer: RECOMPILE

- [x] Should the bootstrap call `Mix.Task.run("app.start")` when running
  outside a project, or is loading code paths sufficient? Some actions may
  need OTP applications started (e.g., `yaml_elixir` needs `:yamerl`).  Answer:
  I don't think any ProGen apps require OTP.  No actions nor validations have
  persistent processes - they are just clean functions.  Let's not worry about
  OTP.

- [x] Should we support `$XDG_CONFIG_HOME` from the start, or hardcode
  `~/.config` for simplicity in v1?  Answer: just `~/.config` for now.
