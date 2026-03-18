# Plan: `@validate` Module Attribute for Actions

## Context

Actions sometimes need precondition checks before `perform/1` runs (e.g., "mix.exs must exist", ".git must exist"). ProGen already has a full validation system (`ProGen.Validate.*` + `ProGen.Validations`), but there's no way to declaratively wire validators into the action call chain. This change adds a `@validate` module attribute so actions can declare preconditions that are automatically checked before execution.

## Design

### Attribute format

```elixir
@validate [{"filesys", [:has_mix, :has_git]}]
```

A list of `{validator_name, checks}` tuples, matching the signature of `ProGen.Validations.run/2`.

### Execution order

```
validate_args → deps → needed? → @validate → perform → confirm
```

Validations run after `needed?/1` (no point checking preconditions if the action is skipped) and before `perform/1`. Fail-fast: first failing check halts execution.

### Introspectability

`validate/0` accessor on each action returns the declared list. This enables future "dry-run all validations across a dependency tree" without executing anything.

## Files to modify

### 1. `lib/pro_gen/action.ex` — Register attribute, inject accessor

- In `__using__/1` (line 42 area): `Module.register_attribute(__MODULE__, :validate, persist: true)`
- In `__before_compile__/1` (line 88 area): Read `@validate`, default to `[]`
- In the injected quote block (line 112 area): Add `def validate, do: unquote(Macro.escape(validate))`
- Update `@moduledoc` to document `@validate`

### 2. `lib/pro_gen/actions.ex` — Run validations in the call chain

- In `run_resolved/3` (line 192-197): After `needed?` passes, call `run_validations(mod)` before `perform_and_confirm`
- Add private `run_validations/1` that iterates the `@validate` list calling `ProGen.Validations.run/2` for each entry, fail-fast with `Enum.reduce_while`
- Update `action_info/1` to include `:validate` key

### 3. Test fixtures — new action modules

- `lib/pro_gen/action/test/validate_pass.ex` — `@validate [{"filesys", [:has_mix]}]` (will pass since tests run from project root)
- `lib/pro_gen/action/test/validate_fail.ex` — `@validate [{"filesys", [:no_mix]}]` (will fail since mix.exs exists)

### 4. `test/pro_gen/action_test.exs` — Attribute accessor tests

- `validate/0` returns `[]` by default (existing actions)
- `validate/0` returns declared list on fixture actions

### 5. `test/pro_gen/actions_test.exs` — Integration tests

- Action with passing `@validate` runs perform successfully
- Action with failing `@validate` returns error, doesn't run perform
- Validation failure includes descriptive error message
- Validation is skipped when `needed?/1` returns false (action is skipped)
- Existing actions (no `@validate`) continue to work unchanged

### 6. `CLAUDE.md` — Update Action docs

- Add `@validate` to the "Adding a new action" section

## Verification

```bash
mix test test/pro_gen/action_test.exs test/pro_gen/actions_test.exs
mix test  # full suite to verify no regressions
```
