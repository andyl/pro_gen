# Plan: File Mods — Mix.exs Code Modification Utility

**Spec:** `_spec/features/260318_file-mods.md`
**Generated:** 2026-03-18

---

## Goal

Create a reusable utility module `ProGen.CodeMods.UsageRules` that can programmatically and
idempotently modify mix.exs files — specifically adding key-value entries to the
`project/0` keyword list and appending private functions to the module.

## Scope

### In scope

- Adding a key-value entry to the `project/0` keyword list (idempotent)
- Adding a `defp` function to a mix.exs module (idempotent)
- AST-based modifications using Igniter
- Clear error handling with `{:ok, _}` / `{:error, reason}` return types
- Working on any valid mix.exs file, not just the ProGen project's own

### Out of scope

- Modifying functions other than `project/0` (e.g., `deps/0`, `aliases/0`)
- Removing or updating existing entries
- Modifying files other than mix.exs
- CLI or Mix task interface
- Formatting preferences or style configuration

## Architecture & Design Decisions

1. **Use Igniter's existing APIs directly.** `Igniter.Project.MixProject.update/4`
   already handles navigating to `project/0`, resolving through private function
   calls and module attributes, and creating the function if missing. For adding
   a key to `project/0`, this is the right tool. For adding a private function,
   `Igniter.update_elixir_file/3` combined with
   `Igniter.Code.Function.move_to_defp/3` (existence check) and
   `Igniter.Code.Common.add_code/3` (insertion) covers the need.

2. **Utility module, not an Action.** The spec explicitly calls for a standalone
   utility module. Place it at `lib/pro_gen/mix_file.ex` as `ProGen.CodeMods.UsageRules`.
   Actions or scripts can call these functions as needed.

3. **Wrap Igniter lifecycle internally.** Each public function creates an
   `Igniter.new()`, performs the modification, and writes changes via
   `Igniter.do_or_dry_run(yes: true)`. The caller does not need to manage
   Igniter structs. Return `{:ok, :updated}` when changes were written,
   `{:ok, :already_exists}` when the operation was a no-op, or
   `{:error, reason}` on failure.

4. **Accept the mix.exs path as a parameter** defaulting to `"mix.exs"` (relative
   to CWD, as Igniter expects). This allows operating on any project's mix.exs.

5. **Function signatures:**
   - `add_to_project(key, value, opts \\ [])` — adds `key: value` to the
     `project/0` keyword list. `value` is a quoted expression or string of
     Elixir code. `opts` accepts `path:` for a custom mix.exs path.
   - `add_defp(name, arity, body, opts \\ [])` — adds a `defp` to the module.
     `body` is a string of the complete function definition. `opts` accepts
     `path:` for a custom mix.exs path.

6. **Idempotency checks:**
   - `add_to_project/3`: Use `Igniter.Code.Keyword.get_key/2` after navigating
     to `project/0` to check if the key exists. If it does, return
     `{:ok, :already_exists}` without modifying anything.
   - `add_defp/4`: Use `Igniter.Code.Function.move_to_defp/3` to check if a
     function with the same name and arity exists. If it does, return
     `{:ok, :already_exists}` without modifying anything.

## Implementation Steps

### 1. Create `lib/pro_gen/mix_file.ex`

- Files: `lib/pro_gen/mix_file.ex`
- Define module `ProGen.CodeMods.UsageRules` with `@moduledoc`.
- Implement `add_to_project/3`:
  1. Create `Igniter.new()`
  2. Use `Igniter.update_elixir_file/3` on the target mix.exs path
  3. Inside the updater, navigate to `def project` using
     `Igniter.Code.Function.move_to_def(zipper, :project, 0)`
  4. Check if the key already exists in the keyword list using
     `Igniter.Code.Keyword.get_key(zipper, key)` — if `{:ok, _}`, return
     the zipper unchanged (no-op)
  5. If key is missing, use `Igniter.Code.Keyword.set_keyword_key/3` to
     insert it
  6. Write with `Igniter.do_or_dry_run(yes: true)` and map the result atom
     to `{:ok, :updated}` or `{:ok, :already_exists}`
- Implement `add_defp/4`:
  1. Create `Igniter.new()`
  2. Use `Igniter.update_elixir_file/3` on the target mix.exs path
  3. Inside the updater, check if `defp name/arity` already exists using
     `Igniter.Code.Function.move_to_defp(zipper, name, arity)`
  4. If it exists, return zipper unchanged (no-op)
  5. If not, navigate to the module's do block and use
     `Igniter.Code.Common.add_code/3` to append the function body
  6. Write and return appropriate result tuple

### 2. Create `test/pro_gen/mix_file_test.exs`

- Files: `test/pro_gen/mix_file_test.exs`
- Use a temporary directory with a sample mix.exs fixture for each test
- Test cases for `add_to_project/3`:
  - Adds a new key-value pair to an empty-ish `project/0`
  - Idempotent: calling twice with the same key is a no-op the second time
  - Works when `project/0` already has existing entries
  - Returns error when the file does not exist or is not parseable
- Test cases for `add_defp/4`:
  - Adds a new `defp` to a module
  - Idempotent: calling twice with the same function name/arity is a no-op
  - Does not interfere with existing functions
  - Returns error when the file does not exist or is not parseable
- Use `File.cd!/2` or explicit `path:` option to point at the temp fixture

### 3. Update `CLAUDE.md`

- Files: `CLAUDE.md`
- Add brief mention of `ProGen.CodeMods.UsageRules` in the Architecture section under
  a "Utilities" heading, describing it as a code modification utility for
  mix.exs files.

## Dependencies & Ordering

1. Step 1 (module) must come first — tests depend on the module existing.
2. Step 2 (tests) should follow immediately to validate the implementation.
3. Step 3 (docs) can happen any time after step 1.

## Edge Cases & Risks

- **Igniter writes to CWD by default.** Tests must use temporary directories
  or explicit paths to avoid modifying the actual project's mix.exs. Use
  `System.tmp_dir!/0` with unique subdirectories per test.
- **Igniter's `do_or_dry_run` prints to stdout.** May need to capture IO in
  tests, or use `Igniter.Test` helpers if available.
- **Value representation for `add_to_project`.** The value passed in (e.g.,
  `usage_rules()`) is a function call, not a simple literal. The API should
  accept either a quoted AST or a string of Elixir code that gets parsed.
  String input is simpler for callers.
- **Function body formatting.** Igniter should handle re-formatting the
  inserted code according to the project's `.formatter.exs`, but verify this
  in tests.
- **mix.exs files without `def project`.** The spec says to return an error.
  Igniter's `move_to_def` returns `:error` in this case — surface that
  as `{:error, "def project/0 not found in mix.exs"}`.

## Testing Strategy

- **Unit tests** in `test/pro_gen/mix_file_test.exs` using temporary mix.exs
  fixture files. Each test creates a temp dir, writes a sample mix.exs, calls
  the function, and reads the file back to verify changes.
- **Idempotency tests** call the same function twice and assert the file
  content is identical after both calls.
- **Error case tests** verify proper error tuples for missing files and
  missing `project/0` definitions.
- Run full suite with `mix test` to ensure no regressions.

## Verification

```bash
mix compile
mix test test/pro_gen/mix_file_test.exs
mix test
mix format --check-formatted
```

## Open Questions

- [ ] Should `add_to_project/3` accept the value as a string of Elixir code
      (e.g., `"usage_rules()"`) or as a quoted AST expression? String is
      simpler for callers but less type-safe. Leaning toward string.
- [ ] Should there be a combined convenience function that does both operations
      at once (add key to project + add the private function it calls)? This
      could be a follow-up.
- [ ] Igniter normally operates relative to CWD. Verify that passing an
      absolute path works, or whether we need to `File.cd!/2` into the
      target project directory first.
