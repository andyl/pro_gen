# Feature Spec: Action Design Overhaul

**Date:** 2026-03-13
**Branch:** `feat/action-design-overhaul`
**Status:** Draft

## Summary

Overhaul the `ProGen.Action` behaviour module to standardize how action
metadata (name, description, option schema) is declared and exposed,
resolve open design questions around data representation, and prepare the
foundation for implementing a suite of built-in action modules.

## Motivation

ProGen is approaching the point where multiple Action modules will be
implemented (echo, inspect, validate, args, mix, file, ask, etc.). The
current `ProGen.Action` behaviour works but leaves several design
decisions unresolved — how hardcoded metadata is declared inside action
modules, how that metadata is inspected from the outside, and whether an
Action struct should exist to carry runtime context. Resolving these
questions now, before building out the action library, will ensure a
consistent and ergonomic API across all actions.

## Requirements

1. **Action metadata via module attributes:** Each action module must
   declare its hardcoded metadata — name, description, and option schema
   — using module attributes (`@name`, `@description`,
   `@option_schema`). The `__using__` macro must register these
   attributes and generate corresponding zero-arity accessor functions
   (`name/0`, `description/0`, `option_schema/0`) so the values are
   inspectable from outside the module.

2. **Derived action name:** The `name/0` function should return the
   action's atom name as derived by the registry (last module segment,
   downcased/underscored). This should be generated automatically by the
   `__using__` macro rather than requiring each action to declare it
   manually.

3. **Callback consolidation:** The `description/0` and
   `option_schema/0` callbacks should be replaced by the
   auto-generated accessor functions backed by module attributes.
   `perform/1` remains the sole required callback that action authors
   implement.

4. **Inherited functions:** The `__using__` macro must continue to
   inject `validate_args/1` and `usage/0` (overridable), and must
   additionally inject the new accessor functions for name, description,
   and option schema.

5. **Action struct (optional enrichment):** Introduce a
   `ProGen.Action.Info` struct (or similar) that bundles an action's
   metadata at runtime. Fields: `module`, `name`, `description`,
   `option_schema`, `usage`. The registry (`ProGen.Actions`) should be
   able to return this struct via a function such as `action_info/1`.

6. **Registry compatibility:** The existing `ProGen.Actions` registry
   (auto-discovery, `persistent_term` caching, duplicate detection) must
   continue to work. The `run/2` function must continue to validate args
   and call `perform/1`, returning `{:ok, result}` or
   `{:error, message}`.

7. **Existing action migration:** The existing `ProGen.Action.Run`
   module must be updated to use the new attribute-based declaration
   style while preserving its current behavior.

## Acceptance Criteria

- Action modules declare `@description` and `@option_schema` as module
  attributes instead of implementing callbacks for those values.
- The `__using__` macro generates `name/0`, `description/0`, and
  `option_schema/0` accessor functions from the declared attributes.
- The action name is auto-derived from the module name — action authors
  do not set it manually.
- `validate_args/1` and `usage/0` continue to work as before.
- `ProGen.Actions.run/2` works without changes to its external API.
- `ProGen.Actions.action_info/1` returns a struct containing the
  action's metadata.
- `ProGen.Action.Run` is migrated to the new style and all existing
  tests pass.
- New tests verify that module attributes are correctly surfaced through
  accessor functions.
- New tests verify the info struct is correctly populated.

## Out of Scope

- Implementation of new action modules (echo, inspect, validate, etc.).
  This spec only covers the behaviour and registry overhaul.
- Changes to `ProGen.Script.action/3` beyond what is needed to
  work with the updated registry.
- Menu system or interactive TUI features.
- Changes to CLI argument parsing (`ProGen.Script` / Optimus).
