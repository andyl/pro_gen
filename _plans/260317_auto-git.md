# Implementation Plan: Auto Git

**Spec:** `_features/260317_auto-git.md`
**Generated:** 2026-03-17

---

## Goal

Auto-commit after every successful `command/2` and `action/3` call in
`ProGen.Script`, and replace the legacy `git/1` and `commit/1` functions with
two new actions: `Git.Init` and `Git.Commit`.

## Scope

### In scope
- New `ProGen.Action.Git.Init` action with `needed?/1`, `perform/1`, and `confirm/2`
- New `ProGen.Action.Git.Commit` action with `needed?/1`, `perform/1`, and `confirm/2`
- Auto-commit integration into `ProGen.Script.command/2` and `ProGen.Script.action/3`
- `commit: true/false` opt-out per call
- Silent skip when no `.git` directory or clean tree
- Removal of `ProGen.Script.git/1` and `ProGen.Script.commit/1`
- Tests for all new functionality

### Out of scope
- Squashing commits at end of script run
- Interactive/selective staging
- Git push or remote operations
- Branch management
- Retry/recovery for failed commits

## Architecture & Design Decisions

1. **Actions over internal helpers:** The spec calls for `Git.Init` and `Git.Commit` as proper actions (not private functions). This is consistent with the project philosophy of composable, discoverable actions. The auto-commit in `Script` will delegate to `ProGen.Actions.run("git.commit", ...)` internally.

2. **`ProGen.Sys.syscmd` for git commands:** Both actions will use `ProGen.Sys.syscmd/2` to run git, consistent with how `ProGen.Action.Run` and the existing `Script.git/1` work. This keeps output streaming behavior uniform.

3. **`command/2` and `action/3` signature changes:** These functions currently take 2 and 3 positional args respectively. To support `commit: false`, `command` needs to accept an optional keyword list as a third argument, and `action` needs to accept it as a fourth argument (or merge it into the existing opts). The cleanest approach is to add an optional trailing `opts` keyword argument to `command/2` → `command/2,3` and extract `commit:` from the existing `opts` in `action/3`.

4. **Guard against circular calls:** The auto-commit in `action/3` must NOT trigger another auto-commit when it internally calls `Actions.run("git.commit", ...)`. Since the auto-commit calls `Actions.run` directly (not `Script.action/3`), there is no recursion risk.

5. **Test isolation:** Git tests need temporary directories with `git init`. Use `System.tmp_dir!/0` + `File.mkdir_p!/1` for test fixtures, and clean up with `on_exit`. Tests should not touch the real project repo.

## Implementation Steps

1. **Create `ProGen.Action.Git.Init`**
   - File: `lib/pro_gen/action/git/init.ex`
   - `@description "Initialize a git repository"`
   - `@option_schema []` (no options needed)
   - `needed?/1`: Check `File.dir?(".git")`, return `false` if it exists
   - `perform/1`: Run `ProGen.Sys.syscmd("git", ["init"])`
   - `confirm/2`: Verify `File.dir?(".git")` returns `true`

2. **Create `ProGen.Action.Git.Commit`**
   - File: `lib/pro_gen/action/git/commit.ex`
   - `@description "Stage all changes and commit"`
   - `@option_schema [message: [type: :string, required: true, doc: "Commit message"]]`
   - `needed?/1`: Run `git status --porcelain` and return `false` if output is empty (clean tree). Also return `false` if `.git` does not exist.
   - `perform/1`: Run `git add .` then `git commit -m "<message>"`
   - `confirm/2`: Check that the perform result was `:ok` (successful exit code)

3. **Add auto-commit helper to `ProGen.Script`**
   - File: `lib/pro_gen/script.ex`
   - Add a private `auto_commit/2` function that takes `(desc, opts)`:
     - If `Keyword.get(opts, :commit, true)` is `false`, no-op
     - Otherwise call `ProGen.Actions.run("git.commit", message: "[ProGen] #{desc}")`
     - Ignore `{:ok, :skipped}` and `:ok` results silently (handles no-git and clean-tree cases)

4. **Update `ProGen.Script.command/2` to support auto-commit**
   - File: `lib/pro_gen/script.ex`
   - Change `command/2` to `command/2,3` — add optional third argument `opts \\ []`
   - After the existing `syscmd` call succeeds, call `auto_commit(desc, opts)`
   - Only auto-commit on success (not on error)

5. **Update `ProGen.Script.action/3` to support auto-commit**
   - File: `lib/pro_gen/script.ex`
   - Extract `commit:` from `opts` before passing the rest to `Actions.run`
   - After the action succeeds, call `auto_commit(desc, commit_opts)`
   - Only auto-commit on success

6. **Remove `ProGen.Script.git/1` and `ProGen.Script.commit/1`**
   - File: `lib/pro_gen/script.ex`
   - Delete the `git/1` function (both clauses: binary and list)
   - Delete the `commit/1` function
   - Update the `@moduledoc` to remove references to `git/1` and `commit/1`

7. **Write tests for `ProGen.Action.Git.Init`**
   - File: `test/pro_gen/action/git/init_test.exs`
   - Test: `run` in a tmp dir without `.git` → succeeds, `.git` created
   - Test: `run` in a dir with `.git` already → `{:ok, :skipped}`
   - Test: `run` with `force: true` in a dir with `.git` → still runs

8. **Write tests for `ProGen.Action.Git.Commit`**
   - File: `test/pro_gen/action/git/commit_test.exs`
   - Test: `run` with dirty tree → commits, returns `:ok`
   - Test: `run` with clean tree → `{:ok, :skipped}`
   - Test: commit message matches the provided `:message` option
   - Test: `run` with no `.git` → `{:ok, :skipped}` (via `needed?/1`)

9. **Write tests for auto-commit integration in `ProGen.Script`**
   - File: `test/pro_gen/script_test.exs` (or inline in existing test file)
   - Test: `command/2` with default opts creates a commit after success
   - Test: `command/3` with `commit: false` does not commit
   - Test: `action/3` with default opts creates a commit after success
   - Test: `action/4` with `commit: false` does not commit
   - Test: auto-commit silently skips when no `.git` directory

10. **Verify all existing tests pass**
    - Run `mix test` to ensure no regressions
    - Verify the action registry discovers `git.init` and `git.commit`

## Dependencies & Ordering

- Steps 1-2 (new actions) are independent of each other and can be done in parallel
- Step 3 (auto-commit helper) depends on step 2 (Git.Commit action exists)
- Steps 4-5 (Script updates) depend on step 3
- Step 6 (remove legacy functions) should happen after steps 4-5 to avoid breaking anything mid-implementation
- Steps 7-8 (action tests) can be written alongside steps 1-2
- Step 9 (integration tests) depends on steps 4-5
- Step 10 is always last

## Edge Cases & Risks

- **Circular auto-commit:** `Script.action/3` calling `Actions.run("git.commit")` internally must not trigger another auto-commit. Mitigation: `auto_commit` calls `Actions.run` directly, not `Script.action`, so there is no recursion.
- **Working directory changes:** `Script.cd/1` changes the BEAM process cwd. The git actions use the current working directory, so `cd` before `command` will correctly scope the commit. No special handling needed.
- **Git not installed:** If `git` is not on the PATH, `Sys.syscmd` will fail. The `needed?/1` check uses `git status`, which will also fail. Mitigation: `needed?/1` should treat command failures as "not needed" (return `false`) rather than crashing.
- **Concurrent test isolation:** Tests that create tmp git repos must not interfere with each other. Mitigation: Use unique tmp dirs per test, and `cd` back in `on_exit`.
- **`command/2` arity change:** Adding an optional third arg changes the function from `command/2` to `command/2,3`. Existing callers using `command/2` are unaffected since the default is `[]`.

## Testing Strategy

- **Unit tests for each action:** Test `needed?/1`, `perform/1`, and `confirm/2` independently in isolated tmp directories with controlled git state.
- **Integration tests for Script:** Test that `command` and `action` produce commits by inspecting `git log` after execution.
- **Negative tests:** Verify `commit: false` suppresses commits, clean trees skip commits, and missing `.git` is handled gracefully.
- **Regression:** Full `mix test` run to ensure existing behavior is preserved.

## Open Questions

- [x] Should `auto_commit` failures (e.g., git commit fails) cause the
  `command/2` or `action/3` call to fail, or should they be silently swallowed?
  The spec says "auto-commit after every *successful* call" but doesn't specify
  what happens if the commit itself fails. Recommendation: log a warning but
  don't fail the script step, since the primary operation already succeeded.
  Answer: follow your recommendation
- [x] The spec says `action/3` — but the current signature is `action(desc,
  name_or_mod, opts \\ [])` which is already 3-arity. Should `commit:` be
  extracted from the existing `opts` keyword list, or should a separate fourth
  argument be added? Recommendation: extract from `opts` to keep the API
  surface minimal.  Answer: follow your recommendation
