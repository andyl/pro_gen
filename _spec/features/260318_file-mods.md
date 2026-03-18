# Feature Spec: File Mods

**Date:** 2026-03-18
**Branch:** `feat/file-mods`
**Status:** Draft

## Summary

A generic, reusable code modification module that can programmatically and
idempotently modify `mix.exs` files — specifically adding lines to the
`project/0` keyword list and adding private functions to the module.

## Motivation

When installing dependencies like `usage_rules`, users are given manual
post-installation instructions: add a key to `def project` and add a new
private function. These manual steps are error-prone and tedious. ProGen needs
a generic codemod capability that can automate these kinds of mix.exs
modifications so that actions and scripts can perform post-install configuration
without user intervention.

## Requirements

1. **Add line to `project/0` block:** Provide a function that inserts a new
   key-value entry into the keyword list returned by `def project` in a
   mix.exs file. If the entry already exists, the operation is a no-op
   (idempotent).

2. **Add private function:** Provide a function that appends a new `defp`
   function to the mix.exs module. If a function with the same name and arity
   already exists, the operation is a no-op (idempotent).

3. **Idempotency:** Both operations must be safe to run multiple times. Running
   the same modification twice must produce the same result as running it once.

4. **Generic and reusable:** The module should not be specific to any single
   dependency. It should work for any key added to `project/0` and any private
   function added to mix.exs.

5. **AST-based modifications:** Use Igniter and/or Sourceror for code
   transformations rather than string manipulation, ensuring that formatting
   and structure are preserved.

6. **Utility module:** Implement as a standalone utility module (not a ProGen
   Action), so the functions can be called from actions, scripts, or any other
   context.

7. **Error handling:** Return clear error tuples when the target file cannot
   be parsed or the expected structure (e.g., `def project`) is not found.

## Acceptance Criteria

- Calling the "add line to project" function with a new key-value pair inserts
  it into the `project/0` keyword list in the target mix.exs file.
- Calling the "add line to project" function with a key that already exists in
  `project/0` makes no changes (idempotent).
- Calling the "add private function" function with new function source appends
  the `defp` to the module in the target mix.exs file.
- Calling the "add private function" function when a `defp` with the same name
  and arity already exists makes no changes (idempotent).
- Both functions work on any valid mix.exs file, not just the ProGen project's
  own mix.exs.
- Both functions return `{:ok, _}` on success and `{:error, reason}` on
  failure.
- All existing tests continue to pass.

## Out of Scope

- Modifying functions other than `project/0` (e.g., `deps/0`, `aliases/0`)
  in this initial implementation.
- Removing or updating existing entries in `project/0`.
- Modifying files other than mix.exs.
- Providing a CLI or Mix task interface for these operations.
- Formatting preferences or style configuration for inserted code.
