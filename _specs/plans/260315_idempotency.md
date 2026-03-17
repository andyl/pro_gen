# Idempotency Predicate for ProGen Actions

## Context

Long-running or side-effecting actions (file creation, package installation,
system commands) benefit from a way to skip re-execution when the desired state
already exists. This adds an optional `needed?/1` predicate to the
`ProGen.Action` behavior that the framework checks before calling `perform/1`.

## Design Rationale

**Comparison to infrastructure tools:**

- **Ansible** — Idempotency is internal to each module; no separate pre-check. Modules report `changed: true/false` after execution. Couples check logic to perform logic.
- **Terraform** — Plan/apply model with external state tracking. Overkill for ProGen's imperative model.
- **Chef** — Closest analog. Separates `load_current_resource` (check) from `converge_if_changed` (act). Clean separation of concerns.
- **Make** — File-timestamp comparisons. Too narrow a metaphor for general-purpose actions.

ProGen's approach follows Chef's pattern: a separate predicate the framework checks before `perform/1`.

**Why `needed?/1` over other names:**

| Candidate       | Verdict                                                                                                        |
|-----------------|----------------------------------------------------------------------------------------------------------------|
| `needed?/1`     | **Chosen.** Natural polarity (`true` = run). Concise. Idiomatic Elixir. Works for create/update/delete/verify. |
| `should_run?/1` | Verbose. "Should" implies policy/opinion.                                                                      |
| `up_to_date?/1` | Inverted polarity (`true` = skip). Inversions cause bugs.                                                      |
| `stale?/1`      | Implies file timestamps. Too narrow.                                                                           |
| `validate`      | Conflicts with existing `validate_args/1`.                                                                     |
| `needs_update`  | Implies updates only. Not a predicate (no `?`).                                                                |

## Implementation

### 1. `lib/pro_gen/action.ex` — Add callback and default

- Add `@callback needed?(args :: keyword()) :: boolean()`
- Inject default `def needed?(_args), do: true` in `__using__` macro (before `validate_args/1`)
- Add `needed?: 1` to the existing `defoverridable` call (alongside `usage: 0`)
- Update `@moduledoc` to document the new callback

### 2. `lib/pro_gen/actions.ex` — Integrate into `run/2`

Modify `run/2` to:
1. Pop `:force` from args before validation: `{force, action_args} = Keyword.pop(args, :force, false)`
2. Validate `action_args` (not the original `args`)
3. After validation succeeds: `if force or mod.needed?(validated_args)` → call `perform/1`, else return `{:ok, :skipped}`

Key properties:
- Validation runs *before* `needed?/1` — invalid args fail fast
- `:force` is popped before `validate_args/1` so it never leaks into action schemas or `perform/1`
- `{:ok, :skipped}` is unambiguously a success outcome

### 3. Tests

**In `test/pro_gen/action_test.exs`:**
- Default `needed?/1` returns `true` for existing actions (Echo, Run)
- Override compiles and works (e.g., file-existence check)

**In `test/pro_gen/actions_test.exs`:**
- Action skipped when `needed?/1` returns `false` → returns `{:ok, :skipped}`
- `force: true` bypasses the check and runs `perform/1`
- `:force` does not leak into validated args
- Validation errors still returned even when `needed?/1` would return `false`
- `needed?/1` receives validated args with defaults applied

### 4. Verify

```bash
mix compile       # no warnings
mix test          # all existing + new tests pass
mix format --check-formatted
```

## Backward Compatibility

Fully backward compatible. Existing actions inherit `def needed?(_args), do: true` — behavior identical to today. No existing module needs changes. No new dependencies.

## Files to Modify

- `lib/pro_gen/action.ex` — Add `@callback`, default impl, `defoverridable`
- `lib/pro_gen/actions.ex` — Modify `run/2` with `needed?/1` check and `force` bypass
- `test/pro_gen/action_test.exs` — Add predicate behavior tests
- `test/pro_gen/actions_test.exs` — Add integration tests
