# Feature Spec: Inspect Action

**Date:** 2026-03-14
**Branch:** `feat/inspect-action`
**Status:** Draft

## Summary

Add a new `ProGen.Action.Inspect` action that accepts any Elixir term and
writes it to stdout using `IO.inspect/2`. This follows the same pattern
established by `ProGen.Action.Echo`.

## Motivation

While the Echo action handles plain string output, there is no built-in
action for inspecting arbitrary Elixir terms. An inspect action gives
scripts a convenient way to debug or display data structures, leveraging
Elixir's built-in `IO.inspect` formatting. It also serves as another
minimal reference implementation of the Action behaviour.

## Requirements

1. **Module:** Create `ProGen.Action.Inspect` under
   `lib/pro_gen/action/inspect.ex` using `use ProGen.Action`.

2. **Option schema:** Declare a single required option `:element` of type
   `:any`. No other options are needed.

3. **Perform:** The `perform/1` callback writes the element to stdout
   using `IO.inspect/1` and returns `:ok`.

4. **Auto-discovery:** The action must be auto-discovered by the existing
   `ProGen.Actions` registry under the name `:inspect`, with no manual
   registration required.

5. **Argument validation:** Missing the required `:element` option must
   return a validation error through the existing NimbleOptions validation
   pipeline.

## Acceptance Criteria

- `ProGen.Actions.run(:inspect, element: %{a: 1})` writes the inspected
  map to stdout and returns `{:ok, :ok}`.
- `ProGen.Actions.run(:inspect, element: [1, 2, 3])` writes the inspected
  list to stdout and returns `{:ok, :ok}`.
- `ProGen.Actions.run(:inspect, element: "hello")` writes the inspected
  string to stdout and returns `{:ok, :ok}`.
- `ProGen.Actions.run(:inspect, [])` returns `{:error, ...}` with a
  validation error indicating the missing required option.
- `ProGen.Action.Inspect.name()` returns `:inspect`.
- `ProGen.Action.Inspect.description()` returns a non-empty string.
- `ProGen.Action.Inspect.option_schema()` returns the NimbleOptions schema
  with a required `:element` key of type `:any`.
- The action appears in the registry's discovered actions list.
- All existing tests continue to pass.

## Out of Scope

- Custom `IO.inspect` options (label, limit, pretty, width, etc.).
- Writing to destinations other than stdout (files, stderr, loggers).
- Multiple elements or variadic input.
- Changes to the Action behaviour or registry.
