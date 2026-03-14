# Implementation Plan: Echo Action

**Spec:** `_features/260314_echo-action.md`
**Generated:** 2026-03-14

---

## Goal

Create a new `ProGen.Action.Echo` action module that accepts a required
`:message` string option and writes it to stdout, following the established
Action behaviour and auto-discovery conventions.

## Scope

### In scope
- New `ProGen.Action.Echo` module with `@description`, `@option_schema`,
  and `perform/1`
- Tests for valid string input (returns `{:ok, :ok}`, writes to stdout)
- Tests for invalid input (list value for `:message` returns validation error)
- Tests for accessor functions (`name/0`, `description/0`, `option_schema/0`)
- Test for registry auto-discovery (action appears in `list_actions/0`)

### Out of scope
- Output formatting, colorization, or styling
- Writing to stderr, files, or loggers
- Multiple messages or variadic input
- Changes to `ProGen.Action` behaviour or `ProGen.Actions` registry

## Architecture & Design Decisions

1. **Follow the Run action pattern exactly.** The existing
   `ProGen.Action.Run` module establishes the convention: `use ProGen.Action`,
   declare `@description` and `@option_schema` as module attributes, implement
   `perform/1` with `@impl true`. Echo will mirror this structure.

2. **Use `IO.puts/1` for output.** This is the standard Elixir function for
   writing a string followed by a newline to stdout. It matches the spec
   requirement and is easily captured in tests via `ExUnit.CaptureIO`.

3. **Return `:ok` from `perform/1`.** The spec states the return value should
   be `:ok`. Since `run/2` wraps the result as `{:ok, result}`, callers will
   see `{:ok, :ok}`.

4. **NimbleOptions `type: :string` for validation.** Setting the `:message`
   option to `type: :string, required: true` means NimbleOptions will
   reject non-string values (lists, integers, etc.) automatically — no
   custom validation code needed.

5. **Test file placement.** Add Echo tests to the existing
   `test/pro_gen_test.exs` file, which already contains all action-related
   tests. This follows the established project convention of a single test
   file.

6. **Use `ExUnit.CaptureIO` for stdout assertions.** Import
   `ExUnit.CaptureIO` and use `capture_io/1` to verify that `perform/1`
   actually writes the message to stdout, rather than only checking the
   return value.

## Implementation Steps

1. **Create the Echo action module**
   - File: `lib/pro_gen/action/echo.ex`
   - Create `ProGen.Action.Echo` with:
     - `use ProGen.Action`
     - `@description "Echo a message to stdout"`
     - `@option_schema [message: [type: :string, required: true, doc: "The message to print"]]`
     - `perform/1` that calls `IO.puts(args[:message])` and returns `:ok`

2. **Add tests for valid string input via the registry**
   - File: `test/pro_gen_test.exs`
   - Add a `describe "ProGen.Action.Echo"` block
   - Test that `ProGen.Actions.run(:echo, message: "hello")` returns
     `{:ok, :ok}`
   - Use `capture_io` to verify `"hello\n"` is written to stdout

3. **Add test for invalid list input**
   - File: `test/pro_gen_test.exs`
   - Test that `ProGen.Actions.run(:echo, message: ["not", "a", "string"])`
     returns `{:error, message}` where `message` is a string containing
     a type validation error

4. **Add tests for accessor functions**
   - File: `test/pro_gen_test.exs`
   - Test `ProGen.Action.Echo.name()` returns `:echo`
   - Test `ProGen.Action.Echo.description()` returns a non-empty string
   - Test `ProGen.Action.Echo.option_schema()` returns a keyword list
     with a `:message` key

5. **Add test for registry auto-discovery**
   - File: `test/pro_gen_test.exs`
   - Test that `:echo` appears in `ProGen.Actions.list_actions()`

6. **Run the full test suite**
   - Run `mix test` to verify all new and existing tests pass

## Dependencies & Ordering

- Step 1 must complete before steps 2–5, since tests depend on the
  module existing and compiling.
- Steps 2–5 can be written together in a single edit pass since they
  are all test additions to the same file.
- Step 6 runs after all code is written.

## Edge Cases & Risks

- **Persistent term cache:** The `ProGen.Actions` registry caches
  discovered actions in `:persistent_term`. In tests, the cache from
  previous test runs may not include the new `:echo` action. However,
  since tests compile all modules fresh each run, and the cache is
  lazily populated, this should not be an issue. If it is, clearing
  persistent terms in the test setup would be the mitigation.

- **IO.puts return value:** `IO.puts/1` returns `:ok`, so `perform/1`
  returning the result of `IO.puts/1` naturally returns `:ok`. But to
  be explicit and resilient, the implementation should explicitly
  return `:ok` after the `IO.puts` call rather than relying on the
  implicit return.

- **Missing `:message` argument:** If `:message` is omitted entirely,
  NimbleOptions will reject it because it is `required: true`. This is
  covered by the existing validation pipeline and does not need a
  separate test beyond what NimbleOptions already guarantees (the Run
  action tests already validate this pattern).

## Testing Strategy

- **Unit tests in `test/pro_gen_test.exs`:** All tests go in the
  existing test file, grouped under a new `describe` block.
- **Capture IO:** Use `import ExUnit.CaptureIO` and `capture_io/1` to
  assert stdout output without side effects.
- **Validation error test:** Pass a list value for `:message` and assert
  the error tuple is returned — this directly addresses the spec
  requirement to test argument handling with invalid types.
- **Run `mix test`** to confirm no regressions across the full suite.

## Open Questions

- None. The spec is clear and the existing codebase conventions provide
  unambiguous guidance for implementation.
