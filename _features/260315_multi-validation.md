# Feature Spec: Multi-Validation

**Date:** 2026-03-15
**Branch:** `feat/multi-validation`
**Status:** Draft

## Summary

Replace the monolithic `ProGen.Action.Validate` with an extensible validation
system. Introduce a `ProGen.Validate` behavior (parallel to `ProGen.Action`)
and a `ProGen.Validations` registry (parallel to `ProGen.Actions`) so that
validation checks can be organized into separate, auto-discovered modules.

## Motivation

The single `ProGen.Action.Validate` module bundles all validation checks into
one place, making it difficult for users to add custom validators or organize
checks by domain (filesystem, networking, environment, etc.). An extensible
system with auto-discovery allows third-party and domain-specific validators
to be added by simply creating a new module under `ProGen.Validate.*`.

## Requirements

1. **Behavior:** Create `ProGen.Validate` behavior module with callbacks
   `checks/0` and `check/1`. The `__using__` macro injects default
   implementations for `check/1`, `checks/0`, `perform/1`, and
   `validate_args/1`.

2. **Registry:** Create `ProGen.Validations` registry with auto-discovery
   of `ProGen.Validate.*` modules, caching in `:persistent_term`, and
   duplicate name detection. Public API: `list_validations/0`,
   `validation_module/1`, `validation_info/1`, `run/2`.

3. **Basics validator:** Create `ProGen.Validate.Basics` migrating all 14
   checks from the old `ProGen.Action.Validate`:
   `:has_mix`, `:no_mix`, `:has_git`, `:no_git`,
   `{:has_file, _}`, `{:no_file, _}`, `{:has_dir, _}`, `{:no_dir, _}`,
   `:has_elixir`, `:no_elixir`, `:has_igniter`, `:no_igniter`,
   `:has_phx_new`, `:no_phx_new`.

4. **Script integration:** Add `ProGen.Script.validate/3` taking a
   description, validator name string, and list of check terms.

5. **Cleanup:** Remove `ProGen.Action.Validate` and its tests.

## Script Integration

From a script, the validator is called via:

```elixir
alias ProGen.Script, as: PG
PG.validate("Check Dependencies", "basics", [:has_mix, :has_git])
```

## Acceptance Criteria

- `ProGen.Validations.run("basics", checks: [:has_mix])` returns `:ok`
  when `mix.exs` exists.
- `ProGen.Validations.run("basics", checks: [:no_mix])` returns
  `{:error, ...}` when `mix.exs` exists.
- `ProGen.Validations.run("basics", checks: [{:has_file, "mix.exs"}])`
  returns `:ok` when `mix.exs` exists.
- All 14 checks from the old module work identically.
- Fail-fast behavior: first failure stops execution.
- `ProGen.Validations.run("basics", [])` returns validation error for
  missing `:checks` option.
- `ProGen.Validations.run("nonexistent", checks: [])` returns error for
  unknown validator.
- `ProGen.Validate.Basics.checks/0` returns introspectable check list.
- `ProGen.Validate.Basics.name()` returns `"basics"`.
- `"basics"` appears in `ProGen.Validations.list_validations()`.
- `ProGen.Action.Validate` no longer exists.
- All existing tests continue to pass.

## Out of Scope

- Auto-search across all validators (explicit validator name required).
- Network/environment validators (future modules).
- Changes to `ProGen.Action` behavior itself.
