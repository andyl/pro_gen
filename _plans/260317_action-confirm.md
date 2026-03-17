# Implementation Plan: Action Confirm Callback

**Spec:** `_features/260317_action-confirm.md`
**Generated:** 2026-03-17

---

## Goal

Add a `confirm/2` postcondition callback to `ProGen.Action` so that after
`perform/1` runs, the action can verify its result and signal failure before
downstream work depends on it.

## Scope

### In scope
- New `confirm/2` callback on `ProGen.Action` behaviour
- Default implementation injected by the `__using__` macro (returns `:ok`)
- Integration into both `run/2` clauses in `ProGen.Actions` (string and atom)
- Test fixture action that exercises `confirm/2`
- Tests for the new callback and its integration with `run/2`

### Out of scope
- Automatic rollback logic
- Changes to `ProGen.Script` or `ProGen.Validations`
- Retry or recovery mechanisms

## Architecture & Design Decisions

1. **Optional callback with default** — follows the same pattern as `needed?/1`:
   the behaviour declares the callback, the `__using__` macro injects a default
   implementation (`def confirm(_result, _args), do: :ok`), and it is listed in
   `defoverridable`. This means existing actions require zero changes.

2. **Error wrapping** — when `confirm/2` returns `{:error, reason}`, `run/2`
   wraps it as `{:error, {:confirmation_failed, reason}}` so callers can
   distinguish confirmation failures from perform failures.

3. **Both run/2 clauses** — `ProGen.Actions.run/2` has two clause heads
   (atom module and string name). Both must be updated identically to call
   `confirm/2` after `perform/1`.

4. **confirm/2 receives raw perform result** — the unmodified return value of
   `perform/1` is passed as the first argument, regardless of its shape. This
   keeps the interface simple and flexible.

## Implementation Steps

1. **Add `confirm/2` callback to `ProGen.Action`**
   - File: `lib/pro_gen/action.ex`
   - Add `@callback confirm(result :: any(), args :: keyword()) :: :ok | {:error, term()}`
   - In the `__using__` macro's `quote` block, add a default implementation:
     `def confirm(_result, _args), do: :ok`
   - Add `confirm: 2` to the `defoverridable` list
   - Update the `@moduledoc` to document the new callback in the lifecycle

2. **Update `run/2` atom clause in `ProGen.Actions`**
   - File: `lib/pro_gen/actions.ex`
   - In `run(mod, args) when is_atom(mod)`, replace the bare
     `mod.perform(validated_args)` with the confirm check:
     ```
     result = mod.perform(validated_args)
     case mod.confirm(result, validated_args) do
       :ok -> result
       {:error, reason} -> {:error, {:confirmation_failed, reason}}
     end
     ```

3. **Update `run/2` string clause in `ProGen.Actions`**
   - File: `lib/pro_gen/actions.ex`
   - Apply the identical confirm-after-perform pattern to
     `run(action_name, args) when is_binary(action_name)`

4. **Create test fixture: `ProGen.Action.Test.ConfirmFail`**
   - File: `lib/pro_gen/action/test/confirm_fail.ex`
   - A minimal action whose `confirm/2` always returns `{:error, "boom"}`.
     Requires a `:message` option (consistent with other test fixtures).

5. **Create test fixture: `ProGen.Action.Test.ConfirmPass`**
   - File: `lib/pro_gen/action/test/confirm_pass.ex`
   - A minimal action whose `confirm/2` returns `:ok` explicitly
     (to test the non-default-but-passing path). Requires a `:message` option.

6. **Add tests for `confirm/2` behaviour defaults**
   - File: `test/pro_gen/action_test.exs`
   - Test that the default `confirm/2` returns `:ok`
   - Test that `confirm/2` can be overridden (compile-time test, same pattern
     as the existing `needed?/1` override test)

7. **Add integration tests for `confirm/2` in `run/2`**
   - File: `test/pro_gen/actions_test.exs`
   - Test: action with no `confirm/2` override still works unchanged
   - Test: action with `confirm/2` returning `:ok` passes through the
     `perform/1` result
   - Test: action with `confirm/2` returning `{:error, reason}` yields
     `{:error, {:confirmation_failed, reason}}`
   - Test: `confirm/2` is NOT called when the action is skipped
     (`needed?/1` returns false, no force)
   - Test: `confirm/2` IS called when force is true even though `needed?/1`
     would return false — wait, `needed?/1` returning false with no force means
     perform is skipped entirely, so confirm is also skipped. With `force: true`,
     perform runs, so confirm runs. This is already covered by the "not called
     when skipped" test plus the existing force tests.

8. **Run tests and verify**
   - Run `mix test` to ensure all existing and new tests pass
   - Run `mix format --check-formatted` to verify formatting

## Dependencies & Ordering

- Step 1 (behaviour change) must come before steps 2-3 (runner integration),
  because the runner calls `mod.confirm/2` which must exist on all action modules.
- Steps 4-5 (test fixtures) must come before steps 6-7 (tests that use them),
  since the test fixtures must be compiled before the tests reference them.
- Steps 2-3 are independent of each other and could be done in either order.
- Step 8 comes last.

## Edge Cases & Risks

- **Existing actions unchanged:** Since the default `confirm/2` returns `:ok`,
  no existing action behaviour changes. The existing test suite is the
  regression safety net.
- **Non-standard perform return values:** `confirm/2` receives whatever
  `perform/1` returns (could be `:ok`, `{:ok, value}`, `{output, exit_code}`,
  etc.). The callback must handle the specific action's return type. This is
  by design — each action knows its own return shape.
- **Duplication in run/2:** Both the atom and string clauses need the same
  confirm logic. Consider extracting a shared private function if the
  duplication feels excessive, but per the project's "avoid over-engineering"
  principle, inline duplication in two places is acceptable.

## Testing Strategy

- **Unit tests** in `action_test.exs`: verify the behaviour default and
  overridability of `confirm/2` at the module level.
- **Integration tests** in `actions_test.exs`: verify the full lifecycle
  through `run/2` — confirm pass-through, confirm failure wrapping, and
  skipped-action bypass.
- **Regression:** running the full `mix test` suite confirms nothing is broken.

## Open Questions

- [x] Should `confirm/2` also receive the `force` flag, or just the validated
  action args? The spec says "validated args" which excludes `:force` (it is
  already popped). This seems correct but worth confirming.  Answer: let's add a force flag later, if needed.
