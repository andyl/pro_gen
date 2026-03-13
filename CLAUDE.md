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

**Behavior module:** `ProGen.Action` defines three callbacks: `perform/1`, `description/0`, `option_schema/0`. The `option_schema/0` callback returns a NimbleOptions schema. The `__using__` macro injects `validate_args/1` (calls NimbleOptions) and an auto-generated `usage/0` (overridable).

**Registry:** `ProGen.Actions` auto-discovers any module whose name starts with `ProGen.Action.` (note: singular `Action`, not `Actions`). The last module name segment is downcased/underscored to derive the action atom name (e.g., `ProGen.Action.Run` → `:run`). Results are lazily cached in `:persistent_term`.

**Running actions:** `ProGen.Actions.run(:action_name, opts)` validates args against the schema then calls `perform/1`. Returns `{:ok, result}` or `{:error, message}`.

**Adding a new action:** Create a module under `lib/pro_gen/action/` named `ProGen.Action.<Name>` that does `use ProGen.Action` and implements the three callbacks (`perform/1`, `description/0`, `option_schema/0`). It will be auto-discovered — no manual registration needed. Action names must be unique across all modules.

### Scripts — End-User Generation Workflows

**Plain functions:** `ProGen.Script` provides plain functions — no macros, callbacks, or `use` required. Call functions as `ProGen.Script.function()`, or `import ProGen.Script` inside a module for unqualified access.

**Core functions:**
- `cli_args(schema)` — Store an Optimus schema in `ProGen.Env` under `:pg_cli_args`.
- `get_schema()` — Retrieve the stored Optimus schema.
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

**System commands:** `ProGen.Sys` provides `syscmd/1` (string) and `syscmd/2` (cmd + args) for running system commands.

**Usage:** Create a `.exs` file that does `Mix.install([{:pro_gen, ...}])`, then call `ProGen.Script.parse_args(schema, System.argv())`. See `examples/greeter.exs`. Note: top-level `import` doesn't work with `Mix.install` scripts (Elixir compile-time limitation); use qualified calls or wrap in a module.

### Menus (Future)

YAML-defined TUI menus for interactive script generation. Not yet implemented.

## Dependencies

- **igniter** — Elixir code generation framework
- **nimble_options** — Action argument validation (also transitive via igniter)
- **optimus** — CLI argv parsing for Scripts

## Design Notes

See `notes/Design.md` for architecture decisions and planned built-in actions (args, mix, run, file, ask, yes?, no?, route). Argument validation uses NimbleOptions for Actions and Optimus for Scripts.
