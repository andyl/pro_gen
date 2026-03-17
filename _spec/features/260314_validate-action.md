# Feature Spec: Validate Action

**Date:** 2026-03-14
**Branch:** `feat/validate-action`
**Status:** Draft

## Summary

Add a new `ProGen.Action.Validate` action that accepts a list of validation
checks and runs each one, reporting success or failure. Each check is an
atom or tuple that maps to a built-in check function. All check functions
are self-contained within the `ProGen.Action.Validate` module and are
introspectable at runtime.

## Motivation

Scripts need a way to assert preconditions before performing generation
tasks — for example, verifying that a directory is empty, that `mix.exs`
does not already exist, or that a required file is present. A dedicated
validate action provides a composable, declarative way to express these
checks. Bundling all checks into a single module keeps the action
self-contained and makes discovery straightforward.

## Requirements

1. **Module:** Create `ProGen.Action.Validate` under
   `lib/pro_gen/action/validate.ex` using `use ProGen.Action`.

2. **Option schema:** Declare a single required option `:checks` of type
   `{:list, :any}`. Each element in the list is either an atom or a tuple
   that identifies a built-in check.

3. **Perform:** The `perform/1` callback iterates over the list of checks,
   calling an internal check function for each one. If all checks pass,
   it returns `:ok`. If any check fails, it returns `{:error, message}`
   with a message describing the first failure.

4. **Check function:** A `check/1` function (public or private — to be
   decided during planning) that accepts an atom or tuple and returns
   `:ok` or `{:error, message}`.

5. **Built-in checks — file existence:**
   - `{:no_file, path}` — passes if the file at `path` does not exist.
   - `{:has_file, path}` — passes if the file at `path` exists.
   - `:no_mix` — shorthand for `{:no_file, "mix.exs"}`.
   - `:has_mix` — shorthand for `{:has_file, "mix.exs"}`.

6. **Built-in checks — directory existence:**
   - `{:no_dir, path}` — passes if the directory at `path` does not exist.
   - `{:has_dir, path}` — passes if the directory at `path` exists.
   - `{:dir_free, path}` — passes if the directory at `path` exists and
     is empty.

7. **Built-in checks — git:**
   - `:no_git` — passes if the `.git` directory does not exist.
   - `:has_git` — passes if the `.git` directory exists.

8. **Introspection:** Provide a way for developers to discover the full
   list of available checks at runtime without reading source code. The
   mechanism (data-driven lookup, documentation function, etc.) is to be
   decided during planning, but all check definitions must remain
   self-contained within `ProGen.Action.Validate`.

9. **Auto-discovery:** The action must be auto-discovered by the existing
   `ProGen.Actions` registry under the name `:validate`, with no manual
   registration required.

10. **Argument validation:** Missing the required `:checks` option must
    return a validation error through the existing NimbleOptions pipeline.

## Script Integration

From a script, the validate action is called via:

```
alias ProGen.Script, as: PG
PG.action "Check Dependencies", :validate, [{:dir_free, "path"}, :no_mix, :no_git]
```

The third argument becomes the `:checks` option list.

## Acceptance Criteria

- `ProGen.Actions.run(:validate, checks: [:no_mix])` returns `{:ok, :ok}`
  when `mix.exs` does not exist.
- `ProGen.Actions.run(:validate, checks: [:has_mix])` returns
  `{:error, ...}` when `mix.exs` does not exist.
- `ProGen.Actions.run(:validate, checks: [{:no_file, "foo.txt"}])`
  returns `{:ok, :ok}` when `foo.txt` does not exist.
- `ProGen.Actions.run(:validate, checks: [{:has_file, "mix.exs"}])`
  returns `{:ok, :ok}` when `mix.exs` exists.
- `ProGen.Actions.run(:validate, checks: [{:no_dir, "nonexistent"}])`
  returns `{:ok, :ok}` when the directory does not exist.
- `ProGen.Actions.run(:validate, checks: [{:has_dir, "lib"}])` returns
  `{:ok, :ok}` when the `lib` directory exists.
- `ProGen.Actions.run(:validate, checks: [:no_git])` returns
  `{:error, ...}` when inside a git repository.
- Multiple checks are evaluated and the first failure stops execution
  with an error.
- `ProGen.Actions.run(:validate, [])` returns `{:error, ...}` with a
  validation error indicating the missing required option.
- The list of available checks is discoverable at runtime through an
  introspection mechanism.
- `ProGen.Action.Validate.name()` returns `:validate`.
- `ProGen.Action.Validate.description()` returns a non-empty string.
- The action appears in the registry's discovered actions list.
- All existing tests continue to pass.

## Out of Scope

- Custom or user-defined check functions (extensibility via plugins).
- Checks that involve network requests or external service availability.
- Splitting check clauses across multiple modules.
- Collecting all failures (fail-fast on first error is sufficient).
- Writing validation results to files or logs.
