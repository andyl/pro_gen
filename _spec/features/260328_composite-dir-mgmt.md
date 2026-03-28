# Feature Spec: Composite Directory Management

**Date:** 2026-03-28
**Branch:** `feat/composite-dir-mgmt`
**Status:** Draft

## Summary

Extend `confirm/2` to optionally return `{:ok, cd: path}`, allowing
project-creating actions (e.g., `new.phoenix`) to signal the runner to change
the working directory before follow-on actions execute.

## Motivation

Composite actions use `depends_on/1` to chain steps. Some actions create a new
project directory, while follow-on actions (`git.init`, `deps.install`) must
run inside it. There is currently no mechanism for an action to tell the runner
"I created a directory -- cd there for what comes next." This forces awkward
workarounds or manual directory management in downstream actions.

## Requirements

1. **Extended `confirm/2` return type:** Update the `ProGen.Action` callback
   typespec to accept `{:ok, keyword()}` in addition to `:ok` and
   `{:error, term()}`.

2. **Runner handles `:cd` option:** Update `perform_and_confirm/2` in
   `ProGen.Actions` so that when `confirm/2` returns `{:ok, opts}`, it
   inspects `opts[:cd]` and calls `File.cd!/1` on that path before proceeding
   to the next action.

3. **Reference implementation in `new.phoenix`:** The `new.phoenix` action's
   `confirm/2` returns `{:ok, cd: project_dir}` on success, where
   `project_dir` is the expanded path of the created project.

4. **Apply to other `new.*` actions:** Actions `new.tableau`, `new.term_ui`,
   and `new.igniter` follow the same pattern as `new.phoenix`.

5. **Backward compatibility:** Actions that return plain `:ok` from `confirm/2`
   continue to work unchanged with no directory change.

## Acceptance Criteria

- `ProGen.Action` typespec for `confirm/2` includes `{:ok, keyword()}`.
- When `confirm/2` returns `{:ok, cd: path}`, the runner changes the working
  directory to `path` before executing subsequent actions.
- When `confirm/2` returns plain `:ok`, the working directory is unchanged.
- When `confirm/2` returns `{:error, reason}`, behavior is unchanged from
  current implementation.
- `new.phoenix` confirm returns `{:ok, cd: project_dir}` when the project
  directory exists after `perform/1`.
- All other `new.*` actions (`tableau`, `term_ui`, `igniter`) follow the same
  pattern.
- All existing tests continue to pass.

## Out of Scope

- Changes to `ProGen.Script` or the validation system.
- Automatic directory restoration or stack-based cd management.
- Any new callbacks or runner changes beyond the `:cd` option.
