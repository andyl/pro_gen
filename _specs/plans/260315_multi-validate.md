# Implementation Plan: Multi-Validation

**Spec:** `_designs/260315_MultiValidation.md`
**Generated:** 2026-03-15

---

## Goal

Replace the monolithic `ProGen.Action.Validate` with an extensible validation
system. Introduce a `ProGen.Validate` behavior (parallel to `ProGen.Action`) and
a `ProGen.Validations` registry (parallel to `ProGen.Actions`) so that validation
checks can be organized into separate, auto-discovered modules.

## Scope

### In scope
- New `ProGen.Validate` behavior module with `__using__` macro
- New `ProGen.Validations` registry with auto-discovery and caching
- New `ProGen.Validate.Basics` module migrating all 14 existing checks
- New `ProGen.Script.validate/3` function for script integration
- Remove `ProGen.Action.Validate` (replaced by the new system)
- Tests for all new modules

### Out of scope
- Auto-search across all validators (explicit validator name required)
- Network/environment validators (future modules, but not this PR)
- Changes to `ProGen.Action` behavior itself

## Architecture & Design Decisions

1. **Separate behavior, parallel to Action.** Validations check preconditions;
   Actions transform state. Different semantics warrant different behaviors with
   different callbacks. `ProGen.Validate` defines `checks/0` and `check/1`
   rather than `perform/1` and `needed?/1`.

2. **Naming convention.** `ProGen.Validate` (behavior, verb form) and
   `ProGen.Validations` (registry, plural) — mirrors `ProGen.Action` /
   `ProGen.Actions`.

3. **Check definitions stay in a private function, not a module attribute.**
   Anonymous functions cannot be stored in module attributes and escaped at
   compile time. The `__using__` macro in `ProGen.Validate` will expect
   implementing modules to define a private `all_checks/0` function (same
   pattern as the existing `ProGen.Action.Validate`).

4. **Registry mirrors `ProGen.Actions` exactly.** Auto-discovers modules
   matching `ProGen.Validate.*`, derives names by dropping the first two
   module segments, caches in `:persistent_term`, detects duplicates.

5. **Explicit validator in Script API.** `Script.validate/3` takes a
   description, validator name string, and list of check terms. No auto-search
   across validators — the caller specifies which validator to use.

6. **Delete `ProGen.Action.Validate`.** All checks move to
   `ProGen.Validate.Basics`. The old action module is removed entirely rather
   than deprecated, since this is early-stage development (v0.1.0).

## Key Files

| File                                    | Action                                                           |
|-----------------------------------------|------------------------------------------------------------------|
| `lib/pro_gen/validate.ex`               | **Create** — Behavior module                                     |
| `lib/pro_gen/validations.ex`            | **Create** — Registry module                                     |
| `lib/pro_gen/validate/basics.ex`        | **Create** — First implementation (migrated checks)              |
| `lib/pro_gen/script.ex`                 | **Modify** — Add `validate/3`                                    |
| `lib/pro_gen/action/validate.ex`        | **Delete** — Replaced by new system                              |
| `test/pro_gen/validate_test.exs`        | **Create** — Behavior tests                                      |
| `test/pro_gen/validations_test.exs`     | **Create** — Registry tests                                      |
| `test/pro_gen/validate/basics_test.exs` | **Create** — Check tests (migrate from action/validate_test.exs) |
| `test/pro_gen/action/validate_test.exs` | **Delete** — Old tests                                           |
| `_features/260315_multi-validation.md`  | **Create** — Feature spec                                        |

## Implementation Steps

### Step 1: Create `ProGen.Validate` behavior

File: `lib/pro_gen/validate.ex`

- Define callbacks: `checks/0` and `check/1`
- `__using__` macro injects:
  - `@behaviour ProGen.Validate`
  - `Module.register_attribute` for `@description` (persisted, required)
  - `@before_compile ProGen.Validate`
  - `validate_args/1` — validates keyword args against `option_schema/0`
    (schema: `[checks: [type: {:list, :any}, required: true]]`)
  - Default `check/1` implementation that looks up term in `all_checks/0`
    and runs the test function (same logic as current `ProGen.Action.Validate.check/1`)
  - Default `checks/0` implementation that maps `all_checks/0` to
    `%{term:, desc:}` (stripping `:fail` and `:test`)
  - `perform/1` — iterates check list via `Enum.reduce_while/3`, fail-fast
- `__before_compile__` macro generates:
  - `name/0` — auto-derived from module segments after `ProGen.Validate`
  - `description/0` — from `@description` attribute
  - `option_schema/0` — hardcoded to `[checks: [type: {:list, :any}, required: true, doc: "List of checks to run"]]`

Key pattern to reuse: `ProGen.Action.__using__/1` and `__before_compile__/1`
at `lib/pro_gen/action.ex:30-88`.

### Step 2: Create `ProGen.Validations` registry

File: `lib/pro_gen/validations.ex`

Mirror `ProGen.Actions` (`lib/pro_gen/actions.ex`) with these changes:
- Prefix: `~c"Elixir.ProGen.Validate."` (discovers `ProGen.Validate.*`)
- Cache keys: `{ProGen.Validations, :validations_list}` and
  `{ProGen.Validations, :validations_map}`
- Public API:
  - `list_validations/0` — sorted list of validator names
  - `validation_module/1` — `{:ok, mod}` or `:error`
  - `validation_info/1` — map with module, name, description, checks
  - `run/2` — validates args, iterates checks via `mod.perform/1`

### Step 3: Create `ProGen.Validate.Basics`

File: `lib/pro_gen/validate/basics.ex`

- `use ProGen.Validate`
- `@description "Basic filesystem and tool checks"`
- Private `all_checks/0` — migrate all 14 checks from
  `lib/pro_gen/action/validate.ex:14-101`:
  - `:has_mix`, `:no_mix`, `:has_git`, `:no_git`
  - `{:has_file, _}`, `{:no_file, _}`, `{:has_dir, _}`, `{:no_dir, _}`
  - `:has_elixir`, `:no_elixir`
  - `:has_igniter`, `:no_igniter`, `:has_phx_new`, `:no_phx_new`

### Step 4: Add `Script.validate/3`

File: `lib/pro_gen/script.ex`

Add function:
```elixir
def validate(desc, validator_name, checks \\ []) do
  log(desc)
  validator_name
  |> ProGen.Validations.run(checks: checks)
  |> halt_on_error()
end
```

### Step 5: Delete old validate action

- Delete `lib/pro_gen/action/validate.ex`
- Delete `test/pro_gen/action/validate_test.exs`

### Step 6: Create tests

**`test/pro_gen/validate_test.exs`** — Behavior tests:
- Module attributes (`name/0`, `description/0`)
- Name derivation from module path

**`test/pro_gen/validations_test.exs`** — Registry tests:
- `list_validations/0` includes `"basics"`
- `validation_module/1` returns correct module
- `validation_info/1` returns metadata map
- `run/2` executes checks, returns `:ok` or `{:error, msg}`
- Unknown validator returns error
- Missing `:checks` option returns validation error

**`test/pro_gen/validate/basics_test.exs`** — Check tests:
- Migrate all tests from `test/pro_gen/action/validate_test.exs`
- Update module references from `ProGen.Action.Validate` to
  `ProGen.Validate.Basics`
- Update `ProGen.Actions.run("validate", ...)` calls to
  `ProGen.Validations.run("basics", ...)`
- All 14 check terms tested
- Fail-fast behavior
- `checks/0` introspection
- Unrecognized term error

### Step 7: Create feature spec

File: `_features/260315_multi-validation.md`

### Step 8: Verify

- `mix compile` — no warnings
- `mix test` — all tests pass
- `mix format --check-formatted` — properly formatted

## Dependencies & Ordering

- Steps 1-3 are sequential (registry needs behavior, Basics needs both)
- Step 4 depends on Step 2 (Script needs Validations registry)
- Step 5 can happen after Step 3 (checks are migrated)
- Step 6 can be written alongside Steps 1-5
- Steps 7-8 are final verification

## Edge Cases & Risks

- **Persistent term cache invalidation:** Tests that compile new validation
  modules may conflict with cached `:persistent_term` values from previous
  test runs. Use the same pattern as Action tests — rely on lazy initialization
  and fresh BEAM per test run.

- **`all_checks/0` as private function:** Same constraint as Action — anonymous
  functions can't be module attributes. Private function is the established
  pattern.

- **Working directory sensitivity:** File/directory checks are relative to CWD.
  Tests use known project files or temp directories with cleanup.

- **Removing `ProGen.Action.Validate`:** Any scripts using
  `PG.action("desc", "validate", [...])` will break. Since this is v0.1.0 with
  no external consumers, this is acceptable. The replacement is
  `PG.validate("desc", "basics", [...])`.

## Open Questions

None. Design decisions were resolved during the discussion phase.
