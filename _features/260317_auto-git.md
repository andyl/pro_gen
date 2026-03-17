# Feature Spec: Auto Git

**Date:** 2026-03-17
**Branch:** `feat/auto-git`
**Status:** Draft

## Summary

Auto-commit after every successful `command/2` or `action/3` call in
`ProGen.Script`, so each step is individually rollbackable via git history.

## Motivation

When a ProGen script runs multiple generation steps, a failure partway through
leaves the working directory in a partially-modified state with no easy way to
undo individual steps. By committing after every successful `command/2` and
`action/3` invocation, each step becomes a discrete git commit that can be
reverted independently. This makes debugging, rollback, and final squashing
straightforward.

## Requirements

1. **Auto-commit after `command/2`:** After a successful `command/2` call in
   `ProGen.Script`, automatically stage all changes and commit with the
   description string (first argument) as the commit message, prefixed with
   `[ProGen]` (e.g., `"[ProGen] Install Phoenix"`).

2. **Auto-commit after `action/3`:** After a successful `action/3` call in
   `ProGen.Script`, automatically stage all changes and commit with the
   description string as the commit message, prefixed with `[ProGen]`.

3. **Default enabled:** Auto-commit is on by default (`commit: true`).

4. **Opt-out per call:** Both `command/2` and `action/3` accept a
   `commit: false` option to skip the auto-commit for that invocation.

5. **Skip if no `.git`:** If the working directory is not a git repository,
   silently skip the commit step (not an error).

6. **Skip on clean tree:** If no files changed after the step, silently skip
   the commit (not an error).

7. **New action `ProGen.Action.Git.Init`:**
   - `needed?/1` returns `false` if `.git` already exists (not an error).
   - `perform/1` runs `git init`.
   - `confirm/2` verifies the `.git` directory exists.

8. **New action `ProGen.Action.Git.Commit`:**
   - `needed?/1` returns `false` if no files have changed (not an error).
   - `perform/1` runs `git add .` followed by `git commit` with the provided
     message.
   - `confirm/2` verifies the commit was successful.

9. **Remove legacy git functions:** Remove the `git/1` and `commit/1`
   functions from `ProGen.Script`, replacing their functionality with the
   new actions.

## Acceptance Criteria

- After a successful `command/2` call, a git commit is created with the
  message `"[ProGen] <description>"` where description is the first argument.
- After a successful `action/3` call, a git commit is created with the
  message `"[ProGen] <description>"`.
- Passing `commit: false` to `command/2` or `action/3` prevents the
  auto-commit for that call.
- When no `.git` directory exists, the auto-commit step is silently skipped.
- When the working tree is clean after a step, the auto-commit step is
  silently skipped.
- `ProGen.Actions.run("git.init", [])` initializes a git repository and
  returns `{:ok, _}`.
- Running `git.init` in an already-initialized repo is skipped via
  `needed?/1` and is not an error.
- `ProGen.Actions.run("git.commit", message: "[ProGen] test")` stages and
  commits all changes.
- Running `git.commit` with a clean working tree is skipped via `needed?/1`
  and is not an error.
- The `git/1` and `commit/1` functions no longer exist in `ProGen.Script`.
- All existing tests continue to pass.

## Out of Scope

- Squashing commits at the end of a script run.
- Interactive or selective staging (partial adds).
- Git push or any remote operations.
- Branch management beyond what `git init` provides.
- Retry or recovery mechanisms for failed commits.
