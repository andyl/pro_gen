# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ProGen is a scriptable Elixir project generator built on [Igniter](https://github.com/ash-project/igniter) for code generation, extended to handle deployment, CI/CD, monitoring, and DevOps tasks. It is in early-stage development (v0.1.0).

## Build & Development Commands

```bash
mix compile          # Compile the project
mix test             # Run all tests (ExUnit)
mix test test/pro_gen_test.exs          # Run a single test file
mix test test/pro_gen_test.exs:LINE     # Run a specific test by line number
mix format           # Format code
mix format --check-formatted            # Check formatting without modifying files
mix deps.get         # Fetch dependencies
```

## Architecture

ProGen has three pillars (Actions are implemented; Scripts and Menus are stubs/future work):

### Actions — Composable Generation Tasks

**Behavior module:** `ProGen.Action` defines callbacks: `perform/1`, `description/0`, `opts_def/0`, plus optional `depends_on/1`, `needed?/1`, and `confirm/2`. The `opts_def/0` callback returns a NimbleOptions schema. The `__using__` macro injects `validate_args/1` (calls NimbleOptions) and an auto-generated `usage/0` (overridable).

**Registry:** `ProGen.Actions` auto-discovers any module whose name starts with `ProGen.Action.` (note: singular `Action`, not `Actions`). The segments after `ProGen.Action` are downcased/underscored and dot-joined to derive the action string name (e.g., `ProGen.Action.Run` → `"run"`, `ProGen.Action.Test.Echo` → `"test.echo"`). Namespaces are arbitrarily deep. Results are lazily cached in `:persistent_term`.

**Running actions:** `ProGen.Actions.run("action_name", opts)` resolves dependencies declared by `depends_on/1`, validates args against the schema, then calls `perform/1`. Dependencies are idempotent (each runs at most once per top-level call) and cycle-safe. Pass `force: true` to bypass `needed?/1` (does not propagate to deps). Returns `{:ok, result}` or `{:error, message}`. Action names are strings (e.g., `"run"`, `"test.echo2"`).

**Adding a new action:** Create a module under `lib/pro_gen/action/` named `ProGen.Action.<Name>` that does `use ProGen.Action` and implements the required callbacks (`perform/1`, `@description`, `@opts_def`). Optionally override `depends_on/1` (returns list of dependency action names or `{name, opts}` tuples), `needed?/1`, and `confirm/2`. Declare `@validate` with a list of `{validator_name, checks}` tuples to add precondition checks before `perform/1` (e.g., `@validate [{"filesys", [:has_mix, :has_git]}]`). It will be auto-discovered — no manual registration needed. Action names must be unique across all modules.

### Scripts — End-User Generation Workflows

**Plain functions:** `ProGen.Script` provides plain functions — no macros, callbacks, or `use` required. Call functions as `ProGen.Script.function()`, or `import ProGen.Script` inside a module for unqualified access.

**Core functions:**
- `cli_args(schema)` — Store an Optimus schema in `ProGen.Env` under `:pg_cli_args`.
- `cli_args()` — Retrieve the stored Optimus schema.
- `parse_args(schema, argv)` — Parse argv (list or string) against an Optimus schema. Returns `{:ok, parsed}` / `{:error, errors}` / `:help` / `:version`.
- `parse_args(argv)` — Parse argv using the stored schema. Merges args/options/flags into a flat map, stores in `:pg_args`. Auto-prints usage on `--help` and version on `--version`.
- `parse_args()` — Convenience that calls `parse_args(System.argv())`.
- `usage(schema)` — Generate help text from an Optimus schema.
- `usage()` — Generate help text from the stored schema.
- `puts(text)` — Print a formatted message.
- `command(desc, command)` — Print description then run a system command.
- `action(desc, action, opts)` — Run a ProGen action (stub).
- `git(arg)` — Run a git command (string or list).
- `commit(message)` — Stage all and commit.

**System commands:** `ProGen.Sys` provides `cmd/1` (string) and `cmd/2` (cmd + args) for running system commands.

**Usage:** Create a `.exs` file that does `Mix.install([{:pro_gen, ...}])`, then call `ProGen.Script.parse_args(schema, System.argv())`. See `examples/greeter.exs`. Note: top-level `import` doesn't work with `Mix.install` scripts (Elixir compile-time limitation); use qualified calls or wrap in a module.

### Utilities

**`ProGen.CodeMods.MixFile`** — Programmatic, idempotent modifications to mix.exs files. Uses Sourceror/Igniter for AST-based code transformations. Two public functions: `add_to_project/3` (inserts a key-value entry into the `project/0` keyword list) and `add_defp/4` (appends a private function to the module). Both are no-ops if the target already exists.

### Menus (Future)

YAML-defined TUI menus for interactive script generation. Not yet implemented.

## Dependencies

- **igniter** — Elixir code generation framework
- **nimble_options** — Action argument validation (also transitive via igniter)
- **optimus** — CLI argv parsing for Scripts

## Design Notes

See `notes/Design.md` for architecture decisions and planned built-in actions (args, mix, run, file, ask, yes?, no?, route). Argument validation uses NimbleOptions for Actions and Optimus for Scripts.
