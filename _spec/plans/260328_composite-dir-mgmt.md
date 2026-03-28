# Implementation Plan: Composite Directory Management

**Spec:** `_spec/features/260328_composite-dir-mgmt.md`
**Generated:** 2026-03-28

---

## Goal

Extend `confirm/2` to optionally return `{:ok, keyword()}` with a `:cd` option, so project-creating actions (e.g., `new.phoenix`) can signal the runner to change the working directory before follow-on actions execute.

## Scope

### In scope
- Extend the `confirm/2` callback typespec to accept `{:ok, keyword()}`
- Update `perform_and_confirm/2` in `ProGen.Actions` to handle `{:ok, opts}` — specifically `opts[:cd]` via `File.cd!/1`
- Update `confirm/2` in all four `new.*` actions: `new.phoenix`, `new.tableau`, `new.igniter`, `new.term_ui`
- Backward compatibility: plain `:ok` and `{:error, term()}` returns unchanged
- Tests for the new behavior

### Out of scope
- Changes to `ProGen.Script` or the validation system
- Automatic directory restoration or stack-based cd management
- New callbacks or runner changes beyond the `:cd` option

## Architecture & Design Decisions

1. **Minimal return-type extension:** `confirm/2` gains `{:ok, keyword()}` as a valid return. The runner pattern-matches the keyword list and acts on recognized keys (`:cd`). Unknown keys are silently ignored, making this forward-extensible without further runner changes.

2. **`File.cd!/1` at the runner level:** The directory change happens inside `perform_and_confirm/2`, immediately after a successful confirm and before control returns to the dependency loop. This means follow-on actions in the same `depends_on` chain will inherit the new working directory — exactly the desired behavior for composite actions like `new.igniter_ops`.

3. **No path expansion in the runner:** The `new.*` actions will expand the path themselves (via `Path.expand/1`) before returning it. The runner trusts the path it receives and simply calls `File.cd!/1`. This keeps the runner generic.

4. **`new.term_ui` module naming:** Note that `new.term_ui` is actually `ProGen.Action.TermUI.New` (not `ProGen.Action.New.TermUI`), so its action name is `"term_ui.new"`, not `"new.term_ui"`. The spec mentions "new.term_ui" but the implementation should follow the actual module. Verify with the user if renaming is intended.

## Implementation Steps

1. **Update `confirm/2` typespec in `ProGen.Action`**
   - File: `lib/pro_gen/action.ex`
   - Change the `@callback confirm` typespec from `:ok | {:error, term()}` to `:ok | {:ok, keyword()} | {:error, term()}`
   - Update the `@moduledoc` to document the new return shape and the `:cd` option

2. **Update `perform_and_confirm/2` in `ProGen.Actions`**
   - File: `lib/pro_gen/actions.ex`
   - In the `perform_and_confirm/2` private function, add a clause matching `{:ok, opts}` when `is_list(opts)`
   - When `opts[:cd]` is a non-nil string, call `File.cd!/1` on that path
   - Return the original `perform/1` result (unchanged — the cd is a side effect)

3. **Update `confirm/2` in `ProGen.Action.New.Phoenix`**
   - File: `lib/pro_gen/action/new/phoenix.ex`
   - On success, return `{:ok, cd: Path.expand(project)}` instead of plain `:ok`

4. **Update `confirm/2` in `ProGen.Action.New.Tableau`**
   - File: `lib/pro_gen/action/new/tableau.ex`
   - Same pattern: return `{:ok, cd: Path.expand(project)}` on success

5. **Update `confirm/2` in `ProGen.Action.New.Igniter`**
   - File: `lib/pro_gen/action/new/igniter.ex`
   - Same pattern: return `{:ok, cd: Path.expand(project)}` on success

6. **Update `confirm/2` in `ProGen.Action.TermUI.New`**
   - File: `lib/pro_gen/action/new/term_ui.ex`
   - Same pattern: return `{:ok, cd: Path.expand(project)}` on success

7. **Add test fixture: `ProGen.Action.Test.ConfirmCd`**
   - File: `test/support/confirm_cd.ex`
   - A lightweight test action whose `confirm/2` returns `{:ok, cd: some_tmp_path}` so the runner's cd behavior can be verified without invoking real `new.*` actions

8. **Add test fixture: `ProGen.Action.Test.ConfirmOkOpts`**
   - File: `test/support/confirm_ok_opts.ex`
   - A test action whose `confirm/2` returns `{:ok, []}` (empty opts) to verify backward-compat: no directory change occurs

9. **Add tests to `ProGen.ActionsTest`**
   - File: `test/pro_gen/actions_test.exs`
   - Test: `confirm/2` returning `{:ok, cd: path}` changes working directory
   - Test: `confirm/2` returning `{:ok, []}` does not change working directory
   - Test: `confirm/2` returning plain `:ok` still works (already covered, but worth a dedicated assertion)
   - Test: follow-on dependency sees the changed directory (verifies ordering with `depends_on`)
   - Each test should save/restore `File.cwd!()` in setup/on_exit to avoid polluting other tests

10. **Verify all existing tests pass**
    - Run `mix test` to confirm no regressions

## Dependencies & Ordering

- Step 1 (typespec) and Step 2 (runner) must come before Steps 3–6 (action updates), since the updated actions will return the new shape.
- Steps 7–8 (test fixtures) must come before Step 9 (tests).
- Steps 3–6 are independent of each other and can be done in any order.
- Step 10 is last.

## Edge Cases & Risks

- **Relative vs absolute paths:** If `confirm/2` returns a relative path, `File.cd!/1` resolves it relative to the current directory at call time. Using `Path.expand/1` in each action avoids ambiguity.
- **Path does not exist:** `File.cd!/1` raises on a nonexistent path. This is acceptable because `confirm/2` only returns `cd:` when the directory was verified to exist. If somehow it doesn't, the crash provides a clear error.
- **Test isolation:** Tests that call `File.cd!/1` must restore the original directory in `on_exit` to avoid breaking subsequent tests.
- **`new.igniter_ops` composite action:** This action depends on `new.igniter`, which will now change the cwd. The follow-on deps (`ops.git_ops`, `ops.commit_hook`) will then run inside the project directory — which is the intended behavior, but verify it works end-to-end.
- **TermUI module naming discrepancy:** The spec says `new.term_ui` but the action name is `term_ui.new`. Clarify with the user whether to rename the module or update the spec.

## Testing Strategy

- **Unit tests** (fast, in-process): Use test fixture actions that return `{:ok, cd: tmp_dir}` and verify `File.cwd!()` changes. Use `System.tmp_dir!/0` or `tmp_dir` ExUnit tag for safe temp directories.
- **Backward-compat tests**: Existing confirm tests (`test.confirm_pass`, `test.confirm_fail`) must continue to pass unchanged.
- **Integration test** (optional, tagged `:slow`): Run `ProGen.Actions.run("new.igniter_ops", project: "test_proj")` in a temp directory and verify the cwd is inside the project after completion.
- **Full suite**: `mix test` must pass with no failures.

## Open Questions

- [x] The spec references `new.term_ui` but the actual action name is `term_ui.new` (module is `ProGen.Action.TermUI.New`). Should the module be moved to `ProGen.Action.New.TermUI` for consistency, or is the spec's wording just informal?  Answer: I fixed the module name.
- [x] Should the runner log/announce the directory change (e.g., via `ProGen.Script.puts`), or should it be silent?  Answer: yes, log the CD event
- [x] Should `File.cd!/1` failures (nonexistent path) be caught and wrapped in `{:error, ...}`, or is letting it raise acceptable?  Answer: raise is OK
