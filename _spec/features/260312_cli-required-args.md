# Feature Spec: CLI Required Args Validation

**Date:** 2026-03-12
**Branch:** `feat/cli-required-args`
**Status:** Draft

## Summary

Update the CLI argument parsing behavior so that when required elements
(args, options) are defined in the Optimus schema but not provided by the
user, the parser automatically prints the usage message and exits the
process instead of returning an error tuple silently.

## Motivation

Currently, when a user invokes a ProGen script without supplying required
arguments, `parse_args/1` returns `{:error, errors}` — but the script
must handle that case manually to show helpful output. This leads to
inconsistent user experience across scripts. The parser should handle
this common case automatically: detect missing required elements, print
the usage message, and halt — matching the behavior already in place for
`--help`.

## Requirements

1. When `parse_args/1` (the single-arity, stored-schema variant) receives
   an `{:error, errors}` result from Optimus **and** the schema contains
   required elements that were not satisfied, it must:
   - Print the usage message to standard output.
   - Halt the process with a non-zero exit code.

2. The two-arity `parse_args/2` (explicit schema variant) must remain
   unchanged — it is a lower-level function and should continue to return
   `{:error, errors}` without side effects, preserving programmatic
   control for callers.

3. The zero-arity `parse_args/0` delegates to `parse_args/1` and should
   inherit the new behavior automatically.

4. The exit behavior should be consistent with how `:help` is handled
   (print then stop), except using a non-zero exit code to signal
   failure.

## Acceptance Criteria

- A script with required args that is invoked with no arguments prints
  the usage message and exits.
- A script with required args that is invoked with all required arguments
  continues to work as before.
- A script with no required args that is invoked with no arguments
  continues to work as before.
- `parse_args/2` still returns `{:error, errors}` without printing or
  halting.
- Existing tests continue to pass.
- New tests cover the updated `parse_args/1` behavior.

## Out of Scope

- Changes to `parse_args/2` behavior.
- Changes to Optimus itself.
- Subcommand support or validation beyond what Optimus already provides.
- Custom error message formatting (use the standard usage output).
