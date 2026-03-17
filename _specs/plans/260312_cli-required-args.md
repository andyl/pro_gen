# Implementation Plan: CLI Required Args Validation

**Spec:** `_specs/260312_cli-required-args.md`
**Generated:** 2026-03-12

---

## Goal

When a ProGen script defines required CLI arguments/options and the user invokes it without them, `parse_args/1` should automatically print the usage message and halt with a non-zero exit code — matching the existing `--help` auto-print behavior but signaling failure.

## Scope

### In scope
- Modify `parse_args/1` in `ProGen.Script` to detect `{:error, _}` results and respond by printing usage + halting.
- `parse_args/0` inherits the new behavior (it delegates to `parse_args/1`).
- New tests covering the updated `parse_args/1` error path.
- Existing tests continue to pass.

### Out of scope
- Changes to `parse_args/2` — it must continue returning `{:error, errors}` without side effects.
- Changes to the Optimus library itself.
- Subcommand support or custom error formatting.

## Architecture & Design Decisions

### 1. Handle all `{:error, _}` from `parse_args/1`, not just "missing required"

The spec says "when required elements were not satisfied." However, Optimus returns `{:error, errors}` for *any* parse failure (missing required options, unknown flags, bad types, etc.). There is no clean way to distinguish "missing required" errors from other parse errors in the Optimus error format without string-matching error messages, which is fragile.

**Decision:** Treat *all* `{:error, _}` results in `parse_args/1` the same way — print usage and halt. This is the expected UX for a CLI tool (any bad invocation shows usage) and avoids fragile error classification. This aligns with the spec's intent: `parse_args/1` is the high-level, script-facing function that should never return an error silently.

### 2. Use `System.halt(1)` for the exit

The spec says "halt the process with a non-zero exit code," consistent with the `--help` pattern. The `:help` branch currently calls `IO.puts()` and returns `:help` (it does *not* halt). For consistency with how CLIs work:

**Decision:** Use `System.halt(1)` after printing usage on error. This matches CLI conventions. The `:help` and `:version` branches already "soft-halt" by returning atoms the script can act on, but for errors the process should stop since there's no useful continuation.

### 3. Print error details before usage

Simply printing usage on error may confuse users ("why is it showing help?"). Printing the specific error message(s) *before* the usage gives context.

**Decision:** Print the error string(s) to stderr via `IO.puts(:stderr, ...)`, then print usage to stdout, then halt with exit code 1.

### 4. Testability — make halt injectable

Calling `System.halt(1)` in tests will kill the test process. We need a way to test the behavior without actually halting.

**Decision:** Extract the halt call into a private function that dispatches to a configurable module attribute or application env. In tests, we can either:
- (a) Use `ExUnit.CaptureIO` + catch the exit, or
- (b) Make the halt function overridable via an optional `:halt_fn` option or a module attribute that defaults to `&System.halt/1` but can be replaced in test setup.

The simplest approach: have `parse_args/1` call a private `halt(code)` function that reads `Application.get_env(:pro_gen, :halt_fn, &System.halt/1)` and invokes it. Tests set this to a function that raises or sends a message instead.

**Alternative (simpler):** Instead of `System.halt/1`, use `exit({:shutdown, 1})` which can be caught in tests. However, this doesn't set the OS exit code in all contexts.

**Final decision:** Use a private `do_halt/1` function backed by `Application.get_env(:pro_gen, :system_halt)`. Default is `&System.halt/1`. Tests override to `fn code -> throw({:halted, code}) end` and wrap calls in `catch_throw`.

## Implementation Steps

1. **Modify `parse_args/1` error branch in `ProGen.Script`**
   - File: `lib/pro_gen/script.ex`
   - Change the `error -> error` catch-all clause in `parse_args/1` to:
     1. Print the error details to stderr.
     2. Print usage to stdout.
     3. Call `do_halt(1)`.
   - Add a private `do_halt/1` function that reads `Application.get_env(:pro_gen, :system_halt, &System.halt/1)` and calls it with the code.

2. **Update the existing `parse_args/1` error test**
   - File: `test/pro_gen/test_scripts/greeter_test.exs`
   - The test at line 127–129 currently asserts `{:error, _} = ProGen.Script.parse_args([])`. This will no longer return `{:error, _}` — it will print + halt. Update this test to:
     - Set `Application.put_env(:pro_gen, :system_halt, fn code -> throw({:halted, code}) end)` in setup.
     - Wrap the call in `catch_throw` and assert `{:halted, 1}` is thrown.
     - Use `capture_io` to verify usage text is printed.
     - Clean up the env in an `on_exit` callback.

3. **Add new tests for `parse_args/1` error behavior**
   - File: `test/pro_gen/test_scripts/greeter_test.exs`
   - Add tests verifying:
     - Missing required options prints usage and halts with code 1.
     - Error messages are printed to stderr.
     - A schema with no required args + empty argv still succeeds (no halt).
     - A schema with required args + all args provided still succeeds.

4. **Verify `parse_args/0` inherits the behavior**
   - No code change needed (`parse_args/0` calls `parse_args(System.argv())`).
   - Add a brief test confirming `parse_args/0` with empty `System.argv()` triggers the same halt behavior (or just rely on the delegation and note it in test comments).

5. **Verify `parse_args/2` is unchanged**
   - No code changes.
   - Existing test at line 40–41 (`greeter_test.exs`) already covers this: `assert {:error, _errors} = ProGen.Script.parse_args(@schema, [])`.
   - Optionally add a comment noting this is intentionally unchanged per the spec.

6. **Run full test suite and format check**
   - Run `mix test` to ensure all tests pass.
   - Run `mix format --check-formatted` to ensure code style compliance.

## Dependencies & Ordering

- Step 1 (modify `parse_args/1`) must happen before Step 2 (update existing test) and Step 3 (new tests), since the tests validate the new behavior.
- Step 2 should happen alongside Step 1 because the existing test will fail as soon as the code changes.
- Steps 4 and 5 are verification-only and depend on Steps 1–3 being complete.
- Step 6 is the final validation and depends on all prior steps.

## Edge Cases & Risks

- **`System.halt/1` in tests:** If the halt function override is not set correctly, `System.halt(1)` will kill the test VM. Mitigation: use `on_exit` callbacks to always restore defaults; consider a test helper module.
- **Optimus error format:** Optimus returns `{:error, [string]}` — a list of error message strings. Verify this format and handle both single-string and list cases when printing.
- **No required args schema:** A schema with only optional flags/options should still work with empty argv. This is already the case since Optimus returns `{:ok, _}` when no required elements are missing.
- **`capture_io` with stderr:** `ExUnit.CaptureIO` captures stdout by default. To capture stderr, use `capture_io(:stderr, fn -> ... end)`. Since we write errors to stderr and usage to stdout, tests may need to capture both streams.
- **Concurrent test safety:** `Application.put_env` is global state. If tests run `async: true`, concurrent tests could interfere. Mitigation: either keep `async: true` and use unique test-scoped overrides, or note that this describe block should not be async. The test file already uses `async: true` — may need to change this or scope carefully.

## Testing Strategy

- **Unit tests** in `test/pro_gen/test_scripts/greeter_test.exs`:
  - Test that `parse_args/1` with missing required args prints usage to stdout, prints error to stderr, and halts with code 1.
  - Test that `parse_args/1` with valid args still returns `{:ok, merged_map}`.
  - Test that `parse_args/2` still returns `{:error, _}` without printing or halting.
- **Manual verification**: Run `examples/greeter.exs` (or a similar script) without args and confirm the usage message appears followed by process exit.
- **Regression**: `mix test` must pass with zero failures.

## Open Questions

- [ ] Should the error messages from Optimus be printed to stderr or stdout? (Plan assumes stderr for errors, stdout for usage — standard CLI convention.) Answer: stderr
- [ ] Should the `:help` branch also call `System.halt(0)` for full CLI consistency? The spec doesn't mention changing `:help` behavior, so leaving it as-is. But it may be worth aligning in a follow-up. Answer: yes
- [ ] Exact Optimus error format — is it always `{:error, [String.t()]}` or can it be `{:error, String.t()}`? Need to verify by checking Optimus source or testing empirically. Answer: not sure.  
