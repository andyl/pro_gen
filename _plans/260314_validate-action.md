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
- Built-in check clauses for file existence, directory existence, and git
- Data-driven introspection mechanism to list available checks at runtime
- Auto-discovery by the existing registry as `:validate`
- Validation error when `:checks` is missing
- Tests covering all acceptance criteria

### Out of scope
- Custom or user-defined check functions (plugin extensibility)
- Network or external service checks
- Splitting checks across multiple modules
- Collecting all failures (fail-fast only)
- Writing validation results to files or logs

## Architecture & Design Decisions

1. **Data-driven check registry via a module attribute.** Define a `@checks`
   module attribute as a list of maps, where each entry describes one check
   clause: its pattern (atom or tuple shape), a human-readable description, and
   the implementation function. This serves dual purpose — it drives both the
   runtime `check/1` dispatch and the introspection API. This approach was
   suggested in the design notes and keeps everything self-contained.

   ```elixir
   @checks [
     %{
       term: :no_mix,
       desc: "Passes if mix.exs does not exist",
       func: fn :no_mix -> check({:no_file, "mix.exs"}) end
     },
     ...
   ]
   ```

2. **Public `check/1` function.** Make `check/1` public so it can be called directly in tests and by scripts that want to run individual checks outside the action pipeline. The function uses pattern matching with multiple clauses — the shorthand atom clauses delegate to the tuple-based clauses.

3. **Public `checks/0` introspection function.** Returns a list of maps with `:term` and `:desc` keys, enabling developers to discover available checks programmatically. This is simpler and more useful than documentation-only approaches.

4. **Fail-fast iteration via `Enum.reduce_while/3`.** The `perform/1` callback iterates the checks list using `Enum.reduce_while/3`, halting on the first `{:error, message}` result. This gives clean early-return semantics without throwing exceptions.

5. **Follow established action patterns.** Use `@description`, `@option_schema`, `Keyword.fetch!/1` after validation — same as Echo and Inspect actions.

6. **Separate test file.** Create `test/pro_gen/action/validate_test.exs` following the pattern used by `echo_test.exs` and `inspect_test.exs`.

## Implementation Steps

1. **Create the Validate action module**
   - File: `lib/pro_gen/action/validate.ex` (new)
   - Define `ProGen.Action.Validate` with `use ProGen.Action`
   - Set `@description "Validate preconditions using declarative checks"`
   - Set `@option_schema [checks: [type: {:list, :any}, required: true, doc: "List of checks to run"]]`
   - Implement `check/1` with pattern-matched clauses for each built-in check:
     - `:no_mix` → delegates to `{:no_file, "mix.exs"}`
     - `:has_mix` → delegates to `{:has_file, "mix.exs"}`
     - `{:no_file, path}` → `:ok` if `!File.exists?(path)`, else `{:error, ...}`
     - `{:has_file, path}` → `:ok` if `File.exists?(path)`, else `{:error, ...}`
     - `{:no_dir, path}` → `:ok` if `!File.dir?(path)`, else `{:error, ...}`
     - `{:has_dir, path}` → `:ok` if `File.dir?(path)`, else `{:error, ...}`
     - `{:dir_free, path}` → `:ok` if `File.dir?(path)` and `File.ls!(path) == []`, else `{:error, ...}`
     - `:no_git` → delegates to `{:no_dir, ".git"}`
     - `:has_git` → delegates to `{:has_dir, ".git"}`
     - Catch-all clause → `{:error, "Unknown check: #{inspect(check)}"}`
   - Implement `checks/0` returning a list of `%{check: pattern, description: text}` maps for all supported checks
   - Implement `perform/1`: fetch `:checks`, iterate with `Enum.reduce_while/3`, return `:ok` or `{:error, message}`

2. **Add tests for the Validate action**
   - File: `test/pro_gen/action/validate_test.exs` (new)
   - Use `ExUnit.Case` with `import ExUnit.CaptureIO` if needed
   - Test cases for each check type, run from a temporary directory where filesystem state is controlled:
     - `:no_mix` passes when no `mix.exs` exists
     - `:has_mix` fails when no `mix.exs` exists
     - `{:no_file, path}` passes when file does not exist
     - `{:has_file, path}` passes when file exists (use `mix.exs` from the project root)
     - `{:no_dir, path}` passes when directory does not exist
     - `{:has_dir, path}` passes when directory exists (use `lib` from the project root)
     - `{:dir_free, path}` passes when directory exists and is empty; fails when non-empty
     - `:no_git` fails when inside a git repo
     - `:has_git` passes when inside a git repo
   - Test fail-fast: multiple checks where the first fails — verify error is from the first failing check
   - Test validation: `run(:validate, [])` returns `{:error, ...}` for missing `:checks`
   - Test unknown check: `run(:validate, checks: [:bogus])` returns `{:error, ...}`
   - Test introspection: `ProGen.Action.Validate.checks/0` returns a non-empty list of maps with `:check` and `:description` keys
   - Test metadata: `name/0` returns `:validate`, `description/0` returns non-empty string, `option_schema/0` includes `:checks`
   - Test auto-discovery: `:validate in ProGen.Actions.list_actions()`

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

- **Persistent term cache:** The `ProGen.Actions` registry caches discovered actions in `:persistent_term`. During tests, the cache from a prior test run may not include the new `:validate` action. Since the test suite compiles all modules fresh each run and `ProGen.Actions` lazily populates the cache, this should work correctly without special handling.

- **Working directory sensitivity:** File and directory checks are relative to the current working directory. Tests should either use absolute paths to known locations (e.g., the project's own `mix.exs` and `lib/` directory) or create temporary directories with controlled content. Using `System.tmp_dir!/0` with setup/teardown is the safest approach for checks like `:dir_free`.

- **`:dir_free` on non-existent directory:** The spec says `:dir_free` passes if the directory "exists and is empty". If the directory does not exist, `File.ls!/1` will raise. The check should return `{:error, ...}` when the directory does not exist, since the precondition ("directory exists") is not met.

- **Unknown check atoms/tuples:** A catch-all `check/1` clause should return `{:error, "Unknown check: ..."}` rather than raising, so the action gracefully reports invalid check names.

- **Path traversal:** The spec does not require sanitizing paths. Checks accept any string path. This is acceptable since the validate action only reads filesystem metadata (existence checks), never modifies files.

## Testing Strategy

- **Unit tests** in `test/pro_gen/action/validate_test.exs` testing each `check/1` clause individually through `ProGen.Actions.run/2`
- **Temporary directories** via `setup` blocks for filesystem-dependent tests (`:dir_free`, `:no_file`, etc.)
- **Known project paths** for simple existence checks (e.g., `mix.exs` and `lib/` are guaranteed to exist in the project root)
- **Validation tests** to confirm NimbleOptions rejects missing required `:checks`
- **Registry integration** to confirm `:validate` appears in `list_actions/0`
- **Metadata tests** for `name/0`, `description/0`, `option_schema/0`, `checks/0`
- **Full suite regression** with `mix test` to ensure no existing tests break

## Open Questions

- [x] Should `check/1` be public or private? Plan recommends public for testability and reuse, but this is a minor decision that can be revisited during implementation. Answer: public for testability
- [x] Exact format of the introspection return value — the plan proposes `%{check: pattern, description: text}` but the key names could differ. Settle on naming during implementation. Answer: the format should be %{term: pattern, desc: text}
