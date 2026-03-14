# Implementation Plan: Action Design Overhaul

**Spec:** `_features/260313_action-design-overhaul.md`
**Generated:** 2026-03-13

---

## Goal

Overhaul `ProGen.Action` so that action metadata (description, option schema)
is declared via module attributes instead of callbacks, auto-derive the action
name from the module name, introduce a `ProGen.Action.Info` struct for runtime
metadata inspection, and migrate the existing `ProGen.Action.Run` module — all
while preserving the external API of `ProGen.Actions`.

## Scope

### In scope
- Replacing `description/0` and `option_schema/0` callbacks with module
  attributes (`@description`, `@option_schema`) and auto-generated accessor
  functions.
- Auto-deriving `name/0` from the module name inside the `__using__` macro.
- Introducing `ProGen.Action.Info` struct with fields: `module`, `name`,
  `description`, `option_schema`, `usage`.
- Updating `ProGen.Actions.action_info/1` to return the new struct.
- Migrating `ProGen.Action.Run` to attribute-based declarations.
- Updating existing tests and adding new tests for attributes and the info
  struct.

### Out of scope
- New action modules (echo, inspect, validate, args, mix, file, ask, etc.).
- Changes to `ProGen.Script`, Optimus parsing, or the menu system.
- Any CLI or TUI work.

## Architecture & Design Decisions

### 1. Module attributes with `before_compile` hook

The `__using__` macro will register `@description` and `@option_schema` as
`Module.register_attribute/3` with `accumulate: false`. A `@before_compile`
hook will read these attributes and inject `name/0`, `description/0`, and
`option_schema/0` as plain functions. This approach is idiomatic Elixir (see
how Phoenix, Ecto, and NimbleOptions themselves use `@before_compile`) and
ensures the attributes are set before functions are generated.

**Why `@before_compile` instead of reading attributes at `__using__` time:**
At `use` time the module body hasn't been evaluated yet, so `@description` and
`@option_schema` haven't been set. `@before_compile` runs after all module
attributes are set but before final compilation, giving us access to the
values.

### 2. Auto-derived `name/0`

The name derivation logic already exists in `ProGen.Actions.action_name_from_module/1`.
We will duplicate a small version of this inside the `__using__` macro's
`@before_compile` callback so that each action module gets a `name/0` function
that returns the atom name (e.g., `:run`). This is a compile-time computation
with no runtime cost.

### 3. Callback reduction

`perform/1` remains the sole `@callback`. The `description/0` and
`option_schema/0` callbacks are removed from the behaviour definition. The
auto-generated accessor functions take their place. This means action authors
only implement `perform/1` and declare two module attributes.

### 4. `ProGen.Action.Info` struct

A dedicated struct replaces the plain map currently returned by
`action_info/1`. Defined inside `ProGen.Action` (as `ProGen.Action.Info`) or
as a separate file — we'll put it in `lib/pro_gen/action/info.ex` for clarity.
Fields: `module`, `name`, `description`, `option_schema`, `usage`.

### 5. Registry (`ProGen.Actions`) changes

- `action_info/1` returns `{:ok, %ProGen.Action.Info{}}` instead of
  `{:ok, %{...}}`.
- `run/2` is unchanged externally. Internally it continues to call
  `mod.validate_args/1` and `mod.perform/1`.
- The private `action_name_from_module/1` stays for registry-side name
  derivation; the `__using__` macro has its own compile-time copy.

## Implementation Steps

1. **Create `ProGen.Action.Info` struct**
   - Files: `lib/pro_gen/action/info.ex` (new)
   - Define `defmodule ProGen.Action.Info` with `defstruct [:module, :name,
     :description, :option_schema, :usage]`.
   - Add a `@type t` typespec.
   - Keep the module minimal — no logic, just the struct definition.

2. **Overhaul `ProGen.Action` behaviour module**
   - Files: `lib/pro_gen/action.ex` (modify)
   - Remove the `description/0` and `option_schema/0` callbacks. Keep only
     `perform/1`.
   - Rewrite the `__using__` macro:
     a. Register `@description` and `@option_schema` as module attributes
        (with `Module.register_attribute/3`).
     b. Register a `@before_compile ProGen.Action` hook.
     c. Keep the injected `validate_args/1` and `usage/0` functions, but
        update them to reference module attributes via the accessor functions
        that `@before_compile` will generate. Since `validate_args/1` and
        `usage/0` call `option_schema()` at runtime, and `option_schema/0`
        will exist after compilation, no change is needed to their bodies —
        they already call `option_schema()` by function name.
   - Implement the `__before_compile__/1` macro:
     a. Read `@description` — raise a compile error if not set.
     b. Read `@option_schema` — default to `[]` if not set.
     c. Derive the action name from `__MODULE__` (split, take last, underscore,
        to_atom).
     d. Define `def name`, `def description`, and `def option_schema` that
        return the attribute values as constants.

3. **Migrate `ProGen.Action.Run` to attribute-based style**
   - Files: `lib/pro_gen/action/run.ex` (modify)
   - Replace the `description/0` callback implementation with
     `@description "Run a system command"`.
   - Replace the `option_schema/0` callback implementation with
     `@option_schema [...]` (the same keyword list).
   - Remove `@impl true` annotations from `description` and `option_schema`
     (they are no longer callbacks).
   - Keep `@impl true` on `perform/1`.
   - The module should now look roughly like:
     ```elixir
     defmodule ProGen.Action.Run do
       use ProGen.Action

       @description "Run a system command"
       @option_schema [
         command: [type: :string, required: true, doc: "The command to execute"],
         args: [type: {:list, :string}, default: [], doc: "Arguments to pass"],
         dir: [type: :string, default: ".", doc: "Working directory"]
       ]

       @impl true
       def perform(args) do
         ...
       end
     end
     ```

4. **Update `ProGen.Actions.action_info/1` to return struct**
   - Files: `lib/pro_gen/actions.ex` (modify)
   - Change `action_info/1` to return `{:ok, %ProGen.Action.Info{...}}`
     instead of `{:ok, %{...}}`.
   - Add `module` and `name` fields to the returned struct (these are newly
     available via the accessor functions).

5. **Update existing tests**
   - Files: `test/pro_gen_test.exs` (modify)
   - Update the `ProGen.Actions.action_info/1` test to assert on the struct
     type (`%ProGen.Action.Info{}`).
   - Verify existing tests for `validate_args/1`, `usage/0`, and `run/2` still
     pass without changes (they should, since the external API is preserved).

6. **Add new tests for module attributes and accessor functions**
   - Files: `test/pro_gen_test.exs` (modify)
   - Add a describe block for the new accessor functions:
     - `ProGen.Action.Run.name/0` returns `:run`.
     - `ProGen.Action.Run.description/0` returns `"Run a system command"`.
     - `ProGen.Action.Run.option_schema/0` returns the expected keyword list.
   - Add a test verifying the info struct fields are all correctly populated
     (module, name, description, option_schema, usage).

7. **Add compile-time validation test**
   - Files: `test/pro_gen_test.exs` (modify)
   - Add a test that defining a module with `use ProGen.Action` but no
     `@description` raises a compile error. Use
     `assert_raise CompileError, fn -> ... end` with `Code.compile_string/1`.

8. **Run full test suite and format**
   - Run `mix test` to verify all existing and new tests pass.
   - Run `mix format` to ensure code style compliance.

## Dependencies & Ordering

- **Step 1 (Info struct) must come before Step 4** — the struct must exist
  before `action_info/1` can return it.
- **Step 2 (Action behaviour overhaul) must come before Step 3** — the
  `__using__` macro must support attribute-based declarations before
  `ProGen.Action.Run` can be migrated.
- **Steps 1 and 2 are independent** and can be done in either order (or
  parallel), since the struct is only consumed in Step 4.
- **Step 3 must come before Steps 5–7** — the migrated module must be in
  place before tests can verify the new behavior.
- **Step 4 can happen any time after Steps 1 and 2.**
- **Step 8 is last** — final verification.

Recommended order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8.

## Edge Cases & Risks

- **Missing `@description`:** If an action author forgets to set
  `@description`, the `@before_compile` hook must raise a clear compile-time
  error. Mitigation: explicit check with a descriptive error message.
- **Missing `@option_schema`:** Some actions may take no options. Defaulting
  to `[]` is reasonable and avoids forcing authors to declare an empty schema.
- **`persistent_term` cache invalidation:** The registry caches action
  modules at first access. If modules are recompiled (e.g., during
  development), stale caches could cause issues. This is a pre-existing
  concern and is out of scope, but worth noting.
- **Name collision between `name/0` derived in the macro vs. the registry:**
  Both use the same algorithm (split → last → underscore → to_atom). If they
  ever diverge, action lookup would break. Mitigation: the derivation logic
  is trivial and identical in both places. A shared helper could be extracted
  later, but for now keeping them in sync is simple enough.
- **`@before_compile` ordering:** If the action module itself defines a
  `@before_compile` hook, ordering could matter. This is unlikely for action
  modules and not worth mitigating now.
- **Backward compatibility of `action_info/1` return type:** Changing from a
  map to a struct could break any code pattern-matching on the map. Since
  structs are maps in Elixir, `info.description` access still works, but
  `%{description: d} = info` patterns will fail unless updated. Mitigation:
  update all call sites (there are currently none outside tests).

## Testing Strategy

- **Existing tests (regression):** All tests in `test/pro_gen_test.exs` must
  continue to pass. These cover `validate_args/1`, `usage/0`, `run/2`, and
  `action_info/1`.
- **Accessor function tests:** Verify `name/0`, `description/0`, and
  `option_schema/0` return the expected values for `ProGen.Action.Run`.
- **Info struct tests:** Verify `ProGen.Actions.action_info(:run)` returns a
  `%ProGen.Action.Info{}` with all fields correctly populated.
- **Compile-time error test:** Verify that omitting `@description` causes a
  `CompileError`.
- **Manual smoke test:** Run `mix compile` and `mix test` to confirm no
  warnings or failures.

## Open Questions

- [x] Should `@option_schema` default to `[]` if not declared, or should it be
  required? (The spec implies it should be part of the attribute set, but some
  actions like `:echo` may take raw args rather than named options. Defaulting
  to `[]` seems pragmatic.)  Answer: default to `[]`
- [x] Should `ProGen.Action.Info` live in its own file
  (`lib/pro_gen/action/info.ex`) or be defined inline within
  `lib/pro_gen/action.ex`? (This plan proposes a separate file for clarity,
  but inlining is also valid given the struct's simplicity.) Answer: live in it's own file
- [x] The design notes mention `@arg_schema` as an alternative name to
  `@option_schema`. The spec settled on `@option_schema` — confirm this is
  final.  Answer: yes let's use @option_schema
