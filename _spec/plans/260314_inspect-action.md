# Implementation Plan: Inspect Action

**Spec:** `_features/260314_inspect-action.md`
**Generated:** 2026-03-14

---

## Goal

Add a `ProGen.Action.Inspect` action that accepts any Elixir term via a required `:element` option and writes it to stdout using `IO.inspect/1`, following the same pattern as `ProGen.Action.Echo`.

## Scope

### In scope
- New `ProGen.Action.Inspect` module with `use ProGen.Action`
- Required `:element` option of type `:any`
- `perform/1` callback using `IO.inspect/1` and returning `:ok`
- Auto-discovery by the existing registry as `:inspect`
- Validation error when `:element` is missing
- Tests covering all acceptance criteria

### Out of scope
- Custom `IO.inspect` options (label, limit, pretty, width)
- Writing to stderr, files, or loggers
- Multiple elements or variadic input
- Changes to the Action behaviour or registry

## Architecture & Design Decisions

1. **Follow the Echo pattern exactly.** The module structure, attribute declarations (`@description`, `@option_schema`), and `perform/1` shape are identical to `ProGen.Action.Echo`. The only differences are the option name (`:element` instead of `:message`), the option type (`:any` instead of `:string`), and the output function (`IO.inspect/1` instead of `IO.puts/1`).

2. **Use NimbleOptions type `:any`.** Since the action must accept arbitrary Elixir terms (maps, lists, tuples, strings, atoms, etc.), `:any` is the correct NimbleOptions type. This still enforces that the key is present when `required: true` is set, but does not restrict the value's type.

3. **Return `:ok` from `perform/1`.** `IO.inspect/1` returns the inspected term, but for consistency with the Echo action pattern, `perform/1` should explicitly return `:ok`. The registry wraps this as `{:ok, :ok}`.

4. **Test stdout capture.** Use `ExUnit.CaptureIO` (already imported in the test file) to assert the inspected output. `IO.inspect/1` appends a newline and uses Elixir's `inspect/1` formatting, so assertions should match that exact format.

## Implementation Steps

1. **Create the Inspect action module**
   - File: `lib/pro_gen/action/inspect.ex` (new)
   - Define `ProGen.Action.Inspect` with `use ProGen.Action`
   - Set `@description "Inspect an Elixir term to stdout"`
   - Set `@option_schema [element: [type: :any, required: true, doc: "The Elixir term to inspect"]]`
   - Implement `perform/1`: fetch `:element` from args, call `IO.inspect/1`, return `:ok`

2. **Add tests for the Inspect action**
   - File: `test/pro_gen_test.exs` (modify)
   - Add a `describe "ProGen.Action.Inspect"` block following the Echo test pattern
   - Test cases:
     - Inspecting a map: `run(:inspect, element: %{a: 1})` captures `"%{a: 1}\n"` and returns `{:ok, :ok}`
     - Inspecting a list: `run(:inspect, element: [1, 2, 3])` captures `"[1, 2, 3]\n"` and returns `{:ok, :ok}`
     - Inspecting a string: `run(:inspect, element: "hello")` captures `"\"hello\"\n"` and returns `{:ok, :ok}`
     - Missing `:element`: `run(:inspect, [])` returns `{:error, message}` with a validation error
     - `name/0` returns `:inspect`
     - `description/0` returns a non-empty string
     - `option_schema/0` includes `:element`
     - Auto-discovery: `:inspect in ProGen.Actions.list_actions()`

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

- **Persistent term cache:** The `ProGen.Actions` registry caches discovered actions in `:persistent_term`. During tests, the cache from a prior test run may not include the new `:inspect` action. However, since the test suite compiles all modules before running, the cache is populated fresh each test run, so this is not a problem in practice.

- **`IO.inspect/1` output format:** The exact output of `IO.inspect/1` depends on Elixir's `Inspect` protocol. For simple terms like `%{a: 1}`, the output is deterministic. Tests should use exact string matching for simple terms but be aware that complex/large terms might have different formatting across Elixir versions. The acceptance criteria use only simple terms, so this is low risk.

- **`IO.inspect/1` returns the term, not `:ok`:** Unlike `IO.puts/1` which returns `:ok`, `IO.inspect/1` returns the inspected value. The `perform/1` function must explicitly return `:ok` after calling `IO.inspect/1` to match the spec's `{:ok, :ok}` expectation.

## Testing Strategy

- **Unit tests via ExUnit** in `test/pro_gen_test.exs`, using `ExUnit.CaptureIO` to capture stdout output
- **Validation tests** to confirm NimbleOptions rejects missing required `:element`
- **Registry integration** to confirm `:inspect` appears in `list_actions/0`
- **Metadata tests** for `name/0`, `description/0`, `option_schema/0`
- **Full suite regression** with `mix test` to ensure no existing tests break

## Open Questions

- None. The spec is clear and the pattern from Echo is well established.
