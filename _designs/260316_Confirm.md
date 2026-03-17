# ProGen Confirm

New `confirm/2` Callback for ProGen.Action

## Problem

We need a way to verify that `perform/1` was successful, then roll back and/or
exit on failure.

## Decision

- Add a **postcondition callback** called `confirm/2`
- Signature: `confirm(result :: any(), args :: keyword()) :: :ok | {:error, term()}`
- Default implementation returns `:ok` (like `needed?/1` defaults to `true`)
- Name chosen to avoid confusion with `validate` (ProGen.Validate already exists)

## Lifecycle

```
needed?(args) -> perform(args) -> confirm(result, args) -> rollback/exit on {:error, _}
```

## Integration in `run/2`

```elixir
if force or mod.needed?(validated_args) do
  result = mod.perform(validated_args)
  case mod.confirm(result, validated_args) do
    :ok -> result
    {:error, reason} -> {:error, {:confirmation_failed, reason}}
  end
else
  {:ok, :skipped}
end
```

## Function Names Considered and Rejected

- `successful?` — didn't resonate
- `verify` — too similar to `validate` (ProGen.Validate)
- `check` — too generic
- `assess` — unusual in code
- `accept` — could be misread
- `ensure` — runner-up, strong "guarantee" connotation

