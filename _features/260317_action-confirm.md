# Feature Spec: Action Confirm Callback

**Date:** 2026-03-17
**Branch:** `feat/action-confirm`
**Status:** Draft

## Summary

Add a `confirm/2` postcondition callback to `ProGen.Action` that verifies
`perform/1` succeeded, enabling rollback or exit on failure.

## Motivation

Currently, actions have no way to verify that their `perform/1` result is
actually correct. If an action produces an unexpected or broken result, the
runner silently returns it as a success. A postcondition callback allows each
action to inspect its own result and signal failure before downstream work
depends on it.

## Requirements

1. **New callback:** Add `confirm/2` to the `ProGen.Action` behaviour with
   signature `confirm(result :: any(), args :: keyword()) :: :ok | {:error, term()}`.

2. **Default implementation:** The `__using__` macro injects a default
   `confirm/2` that returns `:ok` (matching how `needed?/1` defaults to `true`).

3. **Lifecycle integration:** Update `ProGen.Actions.run/2` so that after
   `perform/1` returns, it calls `mod.confirm(result, validated_args)`.
   On `:ok`, return the result as normal. On `{:error, reason}`, return
   `{:error, {:confirmation_failed, reason}}`.

4. **Full lifecycle order:** `needed?(args)` → `perform(args)` →
   `confirm(result, args)` → rollback/exit on `{:error, _}`.

## Acceptance Criteria

- `ProGen.Action` defines `confirm/2` as an optional callback.
- Actions that do not implement `confirm/2` still work unchanged (default
  returns `:ok`).
- An action implementing `confirm/2` returning `:ok` passes through the
  `perform/1` result normally.
- An action implementing `confirm/2` returning `{:error, reason}` causes
  `run/2` to return `{:error, {:confirmation_failed, reason}}`.
- `confirm/2` receives the raw `perform/1` result and the validated args.
- The `confirm/2` callback is only called when `perform/1` is actually
  executed (not when skipped via `needed?/1`).
- All existing tests continue to pass.

## Out of Scope

- Automatic rollback logic (actions handle their own rollback in `confirm/2`
  if needed).
- Changes to `ProGen.Script` or `ProGen.Validations`.
- Retry or recovery mechanisms.
