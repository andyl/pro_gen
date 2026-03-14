# Implementation Plan: Validate Action

**Spec:** `_features/260314_validate-action.md`
**Generated:** 2026-03-14

---

## Goal

Add a `ProGen.Action.Validate` action that accepts a list of declarative checks (atoms or tuples), runs each one, and returns `:ok` if all pass or `{:error, message}` on the first failure. The full set of available checks must be introspectable at runtime.

## Scope

### In scope
- New `ProGen.Action.Validate` module with `use ProGen.Action`
- Required `:checks` option of type `{:list, :any}`
- `perform/1` callback that iterates checks and fails fast on first error
- Data-driven `all_checks/0` private function returning a list of maps (`:term`, `:desc`, `:func`) — the single source of truth for check definitions
- Built-in checks for file existence, directory existence, and git (9 checks total)
- `checks/0` public introspection function
- Auto-discovery by the existing registry as `:validate`
- Tests covering all acceptance criteria

### Out of scope
- Custom or user-defined check functions (plugin extensibility)
- Network or external service checks
- Splitting checks across multiple modules
- Collecting all failures (fail-fast only)
- Writing validation results to files or logs

## Architecture & Design Decisions

1. **Data-driven check registry via a private function.** Define a private `all_checks/0` function that returns a list of maps, where each entry has three keys: `:term` (atom identifying the check), `:desc` (human-readable description), and `:func` (anonymous function implementing the check). This serves dual purpose — it drives both the runtime dispatch and the introspection API. A private function is used instead of a `@checks` module attribute because module attributes containing anonymous functions cannot be escaped into compile-time function bodies.

2. **No separate public `check/1` function.** Individual checks are dispatched entirely through the `all_checks/0` data structure. The `find_check/1` private helper locates entries by matching `:term` — atom checks match directly, tuple checks match the first element (tag). This keeps the API surface minimal.

3. **Public `checks/0` introspection function.** Returns `all_checks/0` with `:func` stripped, yielding a list of `%{term: atom, desc: string}` maps. Enables runtime discovery of available checks.

4. **Fail-fast iteration via `Enum.reduce_while/3`.** The `perform/1` callback iterates the checks list using `Enum.reduce_while/3`, halting on the first `{:error, message}` result or on an unrecognized term. This gives clean early-return semantics without throwing exceptions.

5. **Return value convention.** `perform/1` returns `:ok` on success. On failure, it returns `{:error, message}`. Since `ProGen.Actions.run/2` wraps the result as `{:ok, perform_result}`, callers see `{:ok, :ok}` for success and `{:ok, {:error, message}}` for check failures. Validation-level failures (missing `:checks` option) return `{:error, message}` directly from `run/2`.

6. **Follow established action patterns.** Use `@description`, `@option_schema`, `Keyword.fetch!/2` after validation — same as Echo and Inspect actions.

## Implementation Steps

1. **Create the Validate action module**
   - File: `lib/pro_gen/action/validate.ex` (new)
   - Define `ProGen.Action.Validate` with `use ProGen.Action`
   - Set `@description "Validate preconditions using declarative checks"`
   - Set `@option_schema [checks: [type: {:list, :any}, required: true, doc: "List of checks to run"]]`
   - Implement private `all_checks/0` returning 9 check entries:
     - `:no_mix` — passes if `mix.exs` does not exist
     - `:has_mix` — passes if `mix.exs` exists
     - `:no_git` — passes if `.git` directory does not exist
     - `:has_git` — passes if `.git` directory exists
     - `:no_file` — passes if given file does not exist
     - `:has_file` — passes if given file exists
     - `:no_dir` — passes if given directory does not exist
     - `:has_dir` — passes if given directory exists
     - `:dir_free` — passes if given directory exists and is empty
   - Implement `perform/1` with `Enum.reduce_while/3`
   - Implement `find_check/1` private helper (atom clause + tuple clause)
   - Implement `checks/0` public introspection function

2. **Add tests for the Validate action**
   - File: `test/pro_gen/action/validate_test.exs` (new)
   - Use `ExUnit.Case`
   - Test cases for each check type using known project paths (`mix.exs`, `lib/`, `.git`) and temp directories:
     - `:has_mix` passes, `:no_mix` fails (mix.exs exists in project root)
     - `:has_git` passes, `:no_git` fails (.git exists in project root)
     - `{:has_file, "mix.exs"}` passes, `{:has_file, "nonexistent.txt"}` fails
     - `{:no_file, "nonexistent.txt"}` passes, `{:no_file, "mix.exs"}` fails
     - `{:has_dir, "lib"}` passes, `{:has_dir, "no_such_dir"}` fails
     - `{:no_dir, "no_such_dir"}` passes, `{:no_dir, "lib"}` fails
     - `{:dir_free, tmp}` passes for empty temp dir, fails for non-empty dir, fails for non-existent path
   - Fail-fast: multiple checks where first fails — error is from first failure
   - Missing `:checks` option returns validation error via NimbleOptions
   - Unrecognized term returns error with guidance message mentioning `checks/0`
   - `checks/0` returns non-empty list of maps with `:term` and `:desc` keys, no `:func` key
   - `checks/0` contains all 9 built-in check terms
   - Metadata: `name/0` returns `:validate`, `description/0` returns non-empty string, `option_schema/0` includes `:checks`
   - Auto-discovery: `:validate in ProGen.Actions.list_actions()`

3. **Run the test suite**
   - Command: `mix test`
   - Verify all new and existing tests pass

4. **Run the formatter**
   - Command: `mix format`
   - Verify with `mix format --check-formatted`

## Dependencies & Ordering

Steps are sequential:
- Step 1 must complete before step 2 (tests need the module to exist)
- Step 2 must complete before step 3 (need tests to run)
- Step 4 can run after step 1 but should be verified after step 3

In practice, step 1 and step 2 can be written together, then steps 3 and 4 run to verify.

## Edge Cases & Risks

- **Module attribute vs function for check definitions:** Anonymous functions cannot be stored in module attributes and then referenced at runtime because Elixir cannot escape anonymous functions into compile-time constructs. The solution is to use a private `all_checks/0` function instead of a `@checks` module attribute.

- **Persistent term cache:** The `ProGen.Actions` registry caches discovered actions in `:persistent_term`. Since the test suite compiles all modules fresh each run and the cache is lazily populated, the new `:validate` action is discovered without special handling.

- **Working directory sensitivity:** File and directory checks are relative to the current working directory. Tests use absolute paths to known project files (`mix.exs`, `lib/`) or create temporary directories via `System.tmp_dir!/0` with cleanup in `after` blocks for checks like `:dir_free`.

- **`:dir_free` on non-existent directory:** Returns `{:error, "#{path} is not a directory"}` since the precondition is not met. The `cond` checks `File.dir?/1` before calling `File.ls!/1` to avoid a raise.

- **Unrecognized check terms:** `find_check/1` returns `nil` for unknown terms, and `perform/1` halts with a descriptive error message pointing users to `checks/0`.

- **Path traversal:** The spec does not require sanitizing paths. Checks accept any string path. This is acceptable since the validate action only reads filesystem metadata (existence checks), never modifies files.

## Testing Strategy

- **Unit tests** in `test/pro_gen/action/validate_test.exs` testing each check through `ProGen.Actions.run/2` (25 tests total)
- **Temporary directories** created inline with `try/after` cleanup for `:dir_free` tests
- **Known project paths** for simple existence checks (`mix.exs`, `lib/`, `.git`)
- **Validation tests** to confirm NimbleOptions rejects missing required `:checks`
- **Registry integration** to confirm `:validate` appears in `list_actions/0`
- **Metadata tests** for `name/0`, `description/0`, `option_schema/0`, `checks/0`
- **Full suite regression** with `mix test` to ensure no existing tests break

## Open Questions

- None. All design decisions from the original plan have been resolved during implementation.
