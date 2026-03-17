# Plan: Add `depends_on/1` Callback to ProGen Actions

## Context

Actions sometimes depend on other actions (e.g., `Tableau.New` needs
`Tableau.Install` to run first). Currently there's no way to declare this —
each action would have to manually invoke its dependencies in `perform/1`. This
adds a `depends_on/1` behaviour callback so the runner (`ProGen.Actions.run/2`)
can resolve dependencies automatically, with idempotency, cycle detection, and
per-dependency option control.

## Design Decisions

- **Return type**: `[String.t() | {String.t(), keyword()}]` — bare strings for no-opts deps, tuples when the dependency needs specific options. Normalized internally to `{name, opts}` tuples.
- **Idempotency**: Process dictionary `MapSet` of action names already ran, scoped to the top-level `run/2` call. Cleaned up in `try/after`.
- **Cycle detection**: Process dictionary list used as a resolution stack. If an action name appears in the stack when being resolved, it's a cycle. The stack gives a readable error path.
- **`force: true`**: Does NOT propagate to dependencies. Dependencies manage their own `needed?/1`.
- **Public API**: `run/2` signature unchanged. Dependency resolution is purely internal.

## Changes

### 1. `lib/pro_gen/action.ex` — Add callback + default

- Add `@callback depends_on(args :: keyword()) :: [String.t() | {String.t(), keyword()}]`
- Add default `def depends_on(_args), do: []` in the `__using__` quote block
- Add `depends_on: 1` to `defoverridable`
- Update `@moduledoc` to document the new callback

### 2. `lib/pro_gen/actions.ex` — Dependency resolution in runner

Refactor `run/2` into:

- **`run/2` (public)**: Initializes process dictionary state (ran_set as MapSet, resolving_stack as list) if this is the top-level call. Delegates to `run_internal/2`. Cleans up in `try/after`.
- **`resolve_module/1` (private)**: Extracts the shared module-resolution logic from the two existing `run/2` clauses (atom vs binary). Returns `{:ok, mod}` or `{:error, msg}`.
- **`run_internal/2` (private)**: Core lifecycle:
  1. Pop `force`, resolve module, get `action_name`
  2. Check ran_set → return `{:ok, :already_ran}` if present
  3. Check resolving_stack → return cycle error if present
  4. Validate args
  5. Push onto resolving_stack
  6. Call `run_dependencies/2` (each dep via `run_internal/2`)
  7. `needed?/1` → `perform/1` → `confirm/2`
  8. Record in ran_set, pop from resolving_stack
- **`run_dependencies/2` (private)**: Calls `mod.depends_on(validated_args)`, normalizes, iterates with `Enum.reduce_while`. Any dependency error halts with wrapped error message.
- **`normalize_deps/1` (private)**: `"foo"` → `{"foo", []}`.

### 3. `lib/pro_gen/action/tableau/new.ex` — Wire up the use case

```elixir
@impl true
def depends_on(_args), do: ["tableau.install"]
```

### 4. Test fixtures — New modules in `lib/pro_gen/action/test/`

| Fixture | Purpose |
|---------|---------|
| `Test.DepBase` | No deps, increments a process dict counter on perform |
| `Test.DepChild` | Depends on `test.dep_base` |
| `Test.DepBranchA` | Depends on `test.dep_base` (for diamond) |
| `Test.DepBranchB` | Depends on `test.dep_base` (for diamond) |
| `Test.DepDiamond` | Depends on both branches (idempotency test) |
| `Test.DepCycleA` | Depends on `test.dep_cycle_b` (cycle) |
| `Test.DepCycleB` | Depends on `test.dep_cycle_a` (cycle) |

### 5. `test/pro_gen/actions_test.exs` — New `describe "depends_on/1"` block

Tests:
- Dependencies run before the action
- Diamond: shared dep runs exactly once
- Cycle detection returns clear error
- Dependency failure stops parent
- Default `depends_on/1` returns `[]`
- Dependencies receive their specified options
- Process dictionary cleaned up after run
- `force: true` does not propagate to deps
- Conditional deps (depends_on/1 uses args)

### 6. `CLAUDE.md` — Update action lifecycle docs

Add `depends_on/1` to the callbacks list and lifecycle description.

## Verification

```bash
mix compile
mix test test/pro_gen/actions_test.exs
mix test
mix format --check-formatted
```
