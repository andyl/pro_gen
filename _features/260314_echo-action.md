# Feature Spec: Echo Action

**Date:** 2026-03-14
**Branch:** `feat/echo-action`
**Status:** Draft

## Summary

Add a new `ProGen.Action.Echo` action that accepts a string message and
writes it to stdout. This is a minimal, single-purpose action that
exercises the Action behaviour for simple text output.

## Motivation

ProGen needs a lightweight built-in action for printing text output.
An echo action provides a simple, testable building block that scripts
can use to display messages to the user. It also serves as a
straightforward reference implementation of the Action behaviour.

## Requirements

1. **Module:** Create `ProGen.Action.Echo` under `lib/pro_gen/action/echo.ex`
   using `use ProGen.Action`.

2. **Option schema:** Declare a single required option `:message` of type
   `:string`. No other options are needed.

3. **Perform:** The `perform/1` callback writes the message string to
   stdout (using `IO.puts/1` or equivalent) and returns `:ok`.

4. **Auto-discovery:** The action must be auto-discovered by the existing
   `ProGen.Actions` registry under the name `:echo`, with no manual
   registration required.

5. **Argument validation:** Passing a non-string value (e.g., a list)
   for `:message` must return a validation error through the existing
   NimbleOptions validation pipeline.

## Acceptance Criteria

- `ProGen.Actions.run(:echo, message: "hello")` writes `"hello"` to
  stdout and returns `{:ok, :ok}`.
- `ProGen.Actions.run(:echo, message: ["not", "a", "string"])` returns
  `{:error, ...}` with a validation error indicating the wrong type.
- `ProGen.Action.Echo.name()` returns `:echo`.
- `ProGen.Action.Echo.description()` returns a non-empty string.
- `ProGen.Action.Echo.option_schema()` returns the NimbleOptions schema
  with a required `:message` key of type `:string`.
- The action appears in the registry's discovered actions list.
- All existing tests continue to pass.

## Out of Scope

- Formatting, colorization, or any output styling beyond plain text.
- Writing to destinations other than stdout (files, stderr, loggers).
- Multiple message arguments or variadic input.
- Changes to the Action behaviour or registry.
