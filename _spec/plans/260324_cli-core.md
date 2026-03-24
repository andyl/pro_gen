# Implementation Plan: CLI Core

**Spec:** `_spec/features/260324_cli-core.md`
**Generated:** 2026-03-24

---

## Goal

Add 12 Mix tasks (`progen.action.*`, `progen.validate.*`, `progen.command.run`,
`progen.puts`) that expose ProGen's action, validation, and command
functionality from the command line, enabling interactive terminal use and
composable bash scripts with `set -e` error handling.

## Scope

### In scope
- `ProGen.CLI` shared helper module (name resolution, arg parsing, error
  formatting, auto-commit wrapper)
- 12 Mix task modules under `lib/mix/tasks/progen/`
- Key=value argument parsing for action and validation args
- Module reference resolution (both `"io.echo"` and `"IO.Echo"` forms)
- Non-zero exit codes on error via `Mix.raise/1`
- Auto-commit integration reusing `ProGen.Script` patterns
- Three output formats for list commands: `table`, `text`, `json`
- Tests for `ProGen.CLI` helpers and each Mix task

### Out of scope
- Global archive install (`mix progen.install`)
- 3rd party library integration
- Auto-recompile after `edit` commands
- Interactive prompts for missing arguments
- Progress indicators or spinners

## Architecture & Design Decisions

### 1. Separate Mix tasks (not a single dispatcher)

Each operation gets its own `Mix.Tasks.Progen.*` module. This gives per-task
`@shortdoc` and `@moduledoc` for `mix help`, and enables tab completion via
`mix_completions`. The convention matches how Phoenix, Ecto, and Igniter
structure their tasks.

### 2. `ProGen.CLI` shared helper module

All shared logic lives in `lib/pro_gen/cli.ex` to keep individual Mix task
modules thin. This module provides:

- `resolve_name/1` — Detect uppercase → module form → underscore/dot-join;
  otherwise pass through as-is.
- `parse_kv_args/1` — Split `["key=value", ...]` into a keyword list.
- `auto_commit/3` — Replicates `ProGen.Script`'s private `auto_commit/3`
  logic (check app env, format message with CC support, run `git.commit`).
- `format_commit_message/2` — Same as Script's private helper.
- `format_table/2` — Align columns for list output.
- `format_json/1` — Encode list data as JSON (using Elixir 1.19's built-in
  `JSON` module).
- `halt_on_error/1` — Pattern-match `{:ok, _}` vs `{:error, msg}`, calling
  `Mix.raise/1` on error.
- `source_path/1` — Get source file path from `mod.__info__(:compile)[:source]`.

### 3. Auto-commit logic extraction

Rather than calling `ProGen.Script.action/3` (which has its own logging and
halt behavior), the Mix tasks call `ProGen.Actions.run/2` directly, then call
`ProGen.CLI.auto_commit/3`. This copies the same logic from
`ProGen.Script`'s private `auto_commit/3` and `format_commit_message/2`:
check `Application.get_env(:pro_gen, :auto_commit, true)` + per-invocation
`commit` kwarg, format message with conventional commits if configured, run
`git.commit` action.

### 4. JSON with Elixir 1.19 stdlib

The project targets Elixir `~> 1.19` which includes the built-in `JSON`
module. No additional dependency needed for `--format json`.

### 5. Error handling via `Mix.raise/1`

All error paths call `Mix.shell().error/1` to print to stderr, then
`Mix.raise/1` which exits with code 1. This is the idiomatic Mix way and
works with bash `set -e`. For NimbleOptions validation failures, the error
message includes the action's `usage/0` output.

### 6. Mix task file layout

```
lib/mix/tasks/progen/
  action/
    run.ex      → Mix.Tasks.Progen.Action.Run
    list.ex     → Mix.Tasks.Progen.Action.List
    info.ex     → Mix.Tasks.Progen.Action.Info
    cat.ex      → Mix.Tasks.Progen.Action.Cat
    edit.ex     → Mix.Tasks.Progen.Action.Edit
  validate/
    run.ex      → Mix.Tasks.Progen.Validate.Run
    list.ex     → Mix.Tasks.Progen.Validate.List
    info.ex     → Mix.Tasks.Progen.Validate.Info
    cat.ex      → Mix.Tasks.Progen.Validate.Cat
    edit.ex     → Mix.Tasks.Progen.Validate.Edit
  command/
    run.ex      → Mix.Tasks.Progen.Command.Run
  puts.ex       → Mix.Tasks.Progen.Puts
```

Each module uses `use Mix.Task`, defines `@shortdoc`, `@moduledoc`, and
`run/1`. The `run/1` function parses CLI args, delegates to `ProGen.CLI`
helpers and the underlying API (`ProGen.Actions`, `ProGen.Validations`,
`ProGen.Sys`, `ProGen.Script`), and handles errors.

## Implementation Steps

### Phase 1: Shared Helper Module

1. **Create `ProGen.CLI` module**
   - File: `lib/pro_gen/cli.ex`
   - Functions:
     - `resolve_name(ref)` — If `ref` contains an uppercase letter, split on
       `.`, apply `Macro.underscore/1` to each segment, rejoin with `.`.
       Otherwise return `ref` unchanged.
     - `parse_kv_args(args)` — Takes a list of `"key=value"` strings. For
       each, split on first `=`, convert key to atom, return keyword list.
       Raise clear error if a string has no `=`.
     - `auto_commit(desc, commit_type, opts)` — Check
       `Application.get_env(:pro_gen, :auto_commit, true)` and
       `Keyword.get(opts, :commit, true)`. If both truthy, format message via
       `format_commit_message/2` and run `ProGen.Actions.run("git.commit",
       message: message)`. Log warning on failure (don't crash).
     - `format_commit_message(desc, commit_type)` — If
       `ProGen.Config.use_conventional_commits?()`, return
       `"#{commit_type}: [ProGen] #{desc}"`, else `"[ProGen] #{desc}"`.
     - `source_path(mod)` — Return
       `mod.__info__(:compile)[:source] |> to_string()`.
     - `halt_on_error(result)` — On `{:error, msg}`, call
       `Mix.raise(msg)`. On `{:ok, val}`, return `val`. On `:ok`, return
       `:ok`.
     - `format_table(rows, headers)` — Take list of lists, compute column
       widths, format with padding.
     - `format_list_json(items)` — Convert `[{name, desc}]` to JSON array of
       `{"name": ..., "description": ...}` objects.
   - Details: This is the foundation everything else builds on. Keep it
     focused — just pure functions where possible.

2. **Write tests for `ProGen.CLI`**
   - File: `test/pro_gen/cli_test.exs`
   - Test `resolve_name/1`: `"io.echo"` → `"io.echo"`,
     `"IO.Echo"` → `"io.echo"`, `"Deps.Install"` → `"deps.install"`.
   - Test `parse_kv_args/1`: `["project=my_app", "args=--no-ecto"]` →
     `[project: "my_app", args: "--no-ecto"]`. Test `"has_file=mix.exs"` →
     `[has_file: "mix.exs"]`. Test error on `"noequals"`.
   - Test `format_commit_message/2`: with and without CC enabled.
   - Test `source_path/1` with a known module.
   - Test `format_table/2` and `format_list_json/1` output.

### Phase 2: Action Mix Tasks

3. **Create `mix progen.action.list`**
   - File: `lib/mix/tasks/progen/action/list.ex`
   - Module: `Mix.Tasks.Progen.Action.List`
   - Parse `--format` flag (default `"table"`). Call
     `ProGen.Actions.list_actions/0`. Format and print using
     `ProGen.CLI.format_table/2`, plain text, or JSON.

4. **Create `mix progen.action.info`**
   - File: `lib/mix/tasks/progen/action/info.ex`
   - Module: `Mix.Tasks.Progen.Action.Info`
   - Take one arg (action name). Call `ProGen.CLI.resolve_name/1`, then
     `ProGen.Actions.action_info/1`. Print formatted metadata: module,
     name, description, source path, opts_def, commit type, dependencies
     (call `mod.depends_on([])`), validations, and usage. On error, call
     `Mix.raise/1`.

5. **Create `mix progen.action.run`**
   - File: `lib/mix/tasks/progen/action/run.ex`
   - Module: `Mix.Tasks.Progen.Action.Run`
   - Parse args: first arg is commit message, second is action name, rest
     are key=value pairs. Resolve name, parse kv args, split out `commit`
     kwarg. Call `ProGen.Actions.run/2`. On `{:error, msg}`, check if it's
     a NimbleOptions error — if so, append `usage/0` output. Call
     `ProGen.CLI.auto_commit/3` on success. On error, `Mix.raise/1`.

6. **Create `mix progen.action.cat`**
   - File: `lib/mix/tasks/progen/action/cat.ex`
   - Module: `Mix.Tasks.Progen.Action.Cat`
   - Take one arg (action name). Resolve name, look up module via
     `ProGen.Actions.action_module/1`. Get source path via
     `ProGen.CLI.source_path/1`. Read and print file contents. Error if
     action not found or source file missing.

7. **Create `mix progen.action.edit`**
   - File: `lib/mix/tasks/progen/action/edit.ex`
   - Module: `Mix.Tasks.Progen.Action.Edit`
   - Take one arg (action name). Resolve name, look up module, get source
     path. Get `$EDITOR` (default `"vim"`). Run
     `System.cmd(editor, [path])` to block until editor exits.

### Phase 3: Validation Mix Tasks

8. **Create `mix progen.validate.list`**
   - File: `lib/mix/tasks/progen/validate/list.ex`
   - Module: `Mix.Tasks.Progen.Validate.List`
   - Same pattern as `action.list` but calls
     `ProGen.Validations.list_validations/0`.

9. **Create `mix progen.validate.info`**
   - File: `lib/mix/tasks/progen/validate/info.ex`
   - Module: `Mix.Tasks.Progen.Validate.Info`
   - Same pattern as `action.info` but calls
     `ProGen.Validations.validation_info/1`. Displays module, name,
     description, source path, and available checks.

10. **Create `mix progen.validate.run`**
    - File: `lib/mix/tasks/progen/validate/run.ex`
    - Module: `Mix.Tasks.Progen.Validate.Run`
    - First arg is validator name, rest are check specifications. Simple
      names (no `=`) become atoms. Names with `=` become `{:atom, "value"}`
      tuples. Call `ProGen.Validations.run/2` with `checks:` keyword.
      Error → `Mix.raise/1`.

11. **Create `mix progen.validate.cat`**
    - File: `lib/mix/tasks/progen/validate/cat.ex`
    - Module: `Mix.Tasks.Progen.Validate.Cat`
    - Same pattern as `action.cat` but for validators. Uses
      `ProGen.Validations.validation_module/1`.

12. **Create `mix progen.validate.edit`**
    - File: `lib/mix/tasks/progen/validate/edit.ex`
    - Module: `Mix.Tasks.Progen.Validate.Edit`
    - Same pattern as `action.edit` but for validators.

### Phase 4: Command and Puts Tasks

13. **Create `mix progen.command.run`**
    - File: `lib/mix/tasks/progen/command/run.ex`
    - Module: `Mix.Tasks.Progen.Command.Run`
    - Two args: message and command string. Run via `ProGen.Sys.cmd/1`.
      Auto-commit with commit type `"chore(command)"` on success. Error →
      `Mix.raise/1`.

14. **Create `mix progen.puts`**
    - File: `lib/mix/tasks/progen/puts.ex`
    - Module: `Mix.Tasks.Progen.Puts`
    - Single arg: message string. Call `ProGen.Script.puts/1`.

### Phase 5: Tests

15. **Write Mix task tests**
    - File: `test/pro_gen/cli/action_tasks_test.exs`
    - Test `action.list` in all three formats (table, text, json).
    - Test `action.info` with both name forms (`"test.echo"` and
      `"Test.Echo"`).
    - Test `action.run` with valid args, invalid action name, and invalid
      args (check usage shown).
    - Test `action.cat` prints source.
    - Use `ExUnit.CaptureIO` to capture output.
    - Use test fixture actions from `test/support/`.

16. **Write validation task tests**
    - File: `test/pro_gen/cli/validate_tasks_test.exs`
    - Test `validate.list`, `validate.info`, `validate.run` (simple checks
      and parameterized checks), `validate.cat`.

17. **Write command and puts task tests**
    - File: `test/pro_gen/cli/command_tasks_test.exs`
    - Test `command.run` runs a command and auto-commits.
    - Test `progen.puts` prints formatted output.

18. **Write auto-commit integration tests for CLI**
    - File: `test/pro_gen/cli/auto_commit_test.exs`
    - Set up temp dir with git repo. Run `action.run` via the Mix task.
      Verify commit was created with correct message format. Test with CC
      enabled and disabled. Test `commit=false` suppresses commit.

## Dependencies & Ordering

- **Step 1 (ProGen.CLI) must come first** — all Mix tasks depend on it.
- **Step 2 (CLI tests)** can be written alongside Step 1.
- **Steps 3–7 (action tasks)** depend on Step 1 but are independent of each
  other.
- **Steps 8–12 (validation tasks)** depend on Step 1 but are independent of
  action tasks.
- **Steps 13–14 (command/puts)** depend on Step 1 only.
- **Steps 15–18 (task tests)** depend on the corresponding task modules.
- Action and validation tasks share patterns (list/info/cat/edit). Implement
  action tasks first to establish the pattern, then validation tasks follow
  quickly.

## Edge Cases & Risks

- **Key=value parsing with `=` in value:** Split on first `=` only, so
  `args="--flag=val"` correctly yields `[args: "--flag=val"]`.
- **Atoms from user input:** `parse_kv_args/1` converts keys to atoms via
  `String.to_atom/1`. This is acceptable because Mix tasks run locally (not
  in a server), and the atom table is bounded by the set of valid action
  option keys. NimbleOptions validation will reject unknown keys.
- **Source path availability:** `mod.__info__(:compile)[:source]` may return
  `nil` if compiled without debug info (e.g. release builds). `source_path/1`
  should handle this gracefully with a clear error message.
- **Editor blocking:** `progen.action.edit` and `progen.validate.edit` call
  `System.cmd/2` which blocks. If `$EDITOR` is not set and `vim` is not
  installed, the command fails. Print a helpful error.
- **No actions/validations registered:** `list` commands should print an
  empty table or a "No actions found" message, not crash.
- **Conventional commits disabled by default:** `auto_commit` respects the
  existing `ProGen.Config.use_conventional_commits?()` which defaults to
  `false`. No behavior change for existing users.
- **Duplicate auto_commit logic:** The `ProGen.CLI.auto_commit/3` function
  duplicates `ProGen.Script`'s private function. Consider extracting to a
  shared private module later, but for now duplication is acceptable to avoid
  changing `Script`'s API.

## Testing Strategy

- **Unit tests for `ProGen.CLI`:** Pure function tests for `resolve_name/1`,
  `parse_kv_args/1`, `format_commit_message/2`, `format_table/2`,
  `format_list_json/1`. No side effects.
- **Mix task integration tests:** Use `Mix.Tasks.Progen.Action.List.run/1`
  directly (standard Mix task testing pattern). Capture IO. Use existing
  test fixture actions (`ProGen.Action.Test.*`).
- **Auto-commit tests:** Set up temp dirs with git repos (matching existing
  patterns in `test/pro_gen/script_auto_commit_test.exs`). Verify commit
  messages. Test both CC modes.
- **Error path tests:** Assert that `Mix.raise/1` is called (catch the
  `Mix.Error` exception in tests) with correct messages for: unknown action,
  invalid args, missing `$EDITOR`, etc.
- **All existing tests must continue to pass** — no changes to existing
  modules.

## Open Questions

- [x] Should `action.edit` and `validate.edit` remain in Phase 1, or defer to
  a later phase? They're useful but have the `$EDITOR` dependency and don't
  need the same level of testing rigor. Answer: defer these
- [x] Should `ProGen.CLI.auto_commit/3` be extracted from `ProGen.Script` into
  a shared module (e.g., `ProGen.Git`) to eliminate duplication? This would
  change `Script`'s internals and could be done as a follow-up refactor.  Answer: yes extract now.
- [x] For `--format json`, should `action.info` and `validate.info` also
  support JSON output, or only the `list` commands?  Answer: just the list
- [x] Should `action.run` print the action's return value to stdout on
  success, or only print on error? Current spec is silent on success output.  Answer: don't print the return value, just return it
