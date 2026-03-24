# Feature Spec: CLI Core

**Date:** 2026-03-24
**Branch:** `feat/cli-core`
**Status:** Draft

## Summary

Add 12 Mix tasks to enable running ProGen actions, validations, and commands
from the command line. Supports both interactive terminal use and bash scripts.

## Motivation

ProGen currently works primarily through Elixir scripts (`.exs` files). Users
need a way to run ProGen operations one-at-a-time from a bash terminal, compose
them in bash scripts with `set -e` error handling, and discover available
actions and validations via `mix help`. Separate Mix tasks provide tab
completion via `mix_completions` and per-task help via `mix help <task>`.

## Requirements

### Mix Tasks

1. **`mix progen.action.run "message" <action> [key=value ...]`** — Run a
   named action. First arg is the commit message / description. Second arg is
   the action name. Remaining args are key=value pairs parsed into a keyword
   list and passed to `ProGen.Actions.run/2`. After a successful run,
   auto-commit using the same logic as `ProGen.Script.action/3`.

2. **`mix progen.action.list [--format <fmt>]`** — List all registered actions.
   Calls `ProGen.Actions.list_actions/0`. Formats: `table` (default, aligned
   columns), `text` (one per line), `json` (array of objects).

3. **`mix progen.action.info <action>`** — Show metadata for an action. Calls
   `ProGen.Actions.action_info/1`. Displays: module name, string name,
   description, file path (`mod.__info__(:compile)[:source]`), arguments
   (formatted `opts_def/0`), commit type, dependencies, validations, and usage.

4. **`mix progen.action.cat <action>`** — Print the source code of an action
   module to stdout. Locate source via `mod.__info__(:compile)[:source]`.

5. **`mix progen.action.edit <action>`** — Open the action source file in
   `$EDITOR` (default: `vim`). Block until editor exits.

6. **`mix progen.validate.run <validator> <check> [<check> ...]`** — Run a
   named validator with the specified checks. Simple check names (e.g.,
   `has_mix`) become atoms. Parameterized checks use key=value form (e.g.,
   `has_file=mix.exs` becomes `{:has_file, "mix.exs"}`). Calls
   `ProGen.Validations.run/2` with `checks:` keyword.

7. **`mix progen.validate.list [--format <fmt>]`** — List all registered
   validators. Same format options as action.list.

8. **`mix progen.validate.info <validator>`** — Show metadata for a validator.
   Calls `ProGen.Validations.validation_info/1`. Displays: module name, string
   name, description, file path, and available checks (from `checks/0`).

9. **`mix progen.validate.cat <validator>`** — Print validator source to stdout.

10. **`mix progen.validate.edit <validator>`** — Open validator source in
    `$EDITOR`.

11. **`mix progen.command.run "message" "command"`** — Run a shell command with
    a description. Calls `ProGen.Sys.cmd/1`. After success, auto-commit with
    commit type `"chore(command)"`.

12. **`mix progen.puts "message"`** — Print a formatted message using
    `ProGen.Script.puts/1`.

### Module Reference Resolution

13. **Both name forms accepted:** Action and validation references accept the
    string form (`"deps.install"`) or the module form (`"Deps.Install"`).
    Detection: if the reference contains an uppercase letter, treat it as module
    form — split on `.`, apply `Macro.underscore/1` to each segment, rejoin
    with `.`. Otherwise use as-is.

### Argument Parsing

14. **Key=value pairs:** Arguments after the action/validator name are parsed as
    `key=value` strings. Split on first `=` to get key and value. Keys become
    atoms. Values are strings. Example: `project=my_app args="--no-ecto"`
    becomes `[project: "my_app", args: "--no-ecto"]`.

### Error Handling

15. **Non-zero exit codes:** On error (unknown action, validation failure,
    invalid args, command failure), write the error message to stderr using
    `Mix.shell().error/1` and call `Mix.raise/1` or `System.halt(1)`. This
    enables bash scripts using `set -e` to halt immediately.

16. **Invalid args message:** When args fail NimbleOptions validation, display
    the error and the action's `usage/0` output to help the user correct the
    invocation.

### Auto-Commit Integration

17. **Reuse existing logic:** `action.run` and `command.run` use the same
    auto-commit behavior as `ProGen.Script.action/3` and
    `ProGen.Script.command/2`: stage all changes, commit with
    `[ProGen] <message>` (or conventional commit format if configured). Respect
    the `auto_commit` application env and per-invocation `commit=false` arg.

### Shared Helpers

18. **`ProGen.CLI` module:** Extract shared CLI logic into a helper module:
    module name resolution, key=value parsing, error formatting, auto-commit
    wrapper. All mix tasks delegate to this module to avoid duplication.

## Acceptance Criteria

- `mix progen.action.list` displays all registered actions in table format.
- `mix progen.action.list --format json` outputs valid JSON.
- `mix progen.action.info deps.install` shows full metadata.
- `mix progen.action.info Deps.Install` produces the same result as above.
- `mix progen.action.run "Install Phoenix" new.phoenix project=my_app` parses
  args and runs the action.
- `mix progen.action.run "msg" nonexistent` exits with code 1 and error.
- `mix progen.action.run "msg" io.echo` with missing required arg shows usage.
- `mix progen.action.cat git.commit` prints source code to stdout.
- `mix progen.action.edit git.commit` opens `$EDITOR`.
- `mix progen.validate.run filesys has_mix has_git` runs checks.
- `mix progen.validate.run filesys has_file=mix.exs` runs parameterized check.
- `mix progen.command.run "Say hello" "echo hello"` runs command and commits.
- `mix progen.puts "Hello"` prints formatted message.
- After `action.run` succeeds in a git repo, a commit is created.
- Conventional commits config is respected when present.
- All existing tests continue to pass.

## Out of Scope

- Global archive install (covered in CLI Extras spec).
- `mix progen.install` (covered in CLI Extras spec).
- 3rd party library integration (covered in CLI Extras spec).
- `mix progen.compile` — recompilation after edit is manual.
- Auto-recompile after `edit` commands.
- Interactive prompts for missing arguments.
- Progress indicators or spinners.
