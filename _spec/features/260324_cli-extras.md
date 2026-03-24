# Feature Spec: CLI Extras

**Date:** 2026-03-24
**Branch:** `feat/cli-extras`
**Status:** Draft

## Summary

Extend ProGen's CLI with global archive installation and 3rd party library
support. Users define dependencies in `~/.config/pro_gen/config.yml` and run
`mix progen.install` to fetch, compile, and make them discoverable alongside
ProGen's built-in actions and validations.

## Motivation

The CLI Core spec requires ProGen as a project dependency, limiting use to Mix
projects that explicitly depend on it. Users need ProGen available globally —
from any directory, in bash scripts, and with community-contributed action
libraries. A thin Mix archive provides the entry point, while an install
mechanism fetches ProGen itself and any 3rd party libs into a shared location.

## Requirements

### Archive Structure

1. **Thin archive:** Package a minimal Mix archive containing only the 12 mix
   task modules (from CLI Core) plus a bootstrap module. Install via
   `mix archive.install github andyl/pro_gen`.

2. **Bootstrap module (`ProGen.CLI.Bootstrap`):** When a mix task runs, the
   bootstrap checks if ProGen modules are available. If not (outside a project),
   it adds `~/.config/pro_gen/deps/*/ebin` to the code path via
   `Code.prepend_path/1`. If still unavailable, it prints an error directing
   the user to run `mix progen.install`.

### Install Command

3. **`mix progen.install`:** Read `~/.config/pro_gen/config.yml`, fetch all
   listed libraries (including ProGen itself) into
   `~/.config/pro_gen/deps/<lib>/`, and compile them. Create the config
   directory if it does not exist.

4. **ProGen self-install:** ProGen itself is included in the deps directory so
   all its modules and dependencies (igniter, nimble_options, yaml_elixir, etc.)
   are available globally. The install command creates a temporary Mix project
   with ProGen and all configured libs as dependencies, compiles it, and copies
   the compiled ebin directories to `~/.config/pro_gen/deps/`.

### Config File

5. **Location:** `~/.config/pro_gen/config.yml` (or `.yaml`). Optional — if
   absent, `install` installs only ProGen itself with defaults.

6. **Format:**
   ```yaml
   libs:
     - name: my_actions
       path: /home/user/projects/my_actions
     - name: team_utils
       github: myorg/pro_gen_utils
     - name: community_pack
       hex: pro_gen_community
       version: "~> 0.2"
   ```

7. **Source types:**
   - `path:` — local directory (symlinked, not copied)
   - `github:` — cloned via git
   - `hex:` with optional `version:` — fetched from Hex.pm

### Deps Directory

8. **Structure:**
   ```
   ~/.config/pro_gen/
     config.yml
     deps/
       pro_gen/ebin/       # ProGen itself
       igniter/ebin/       # ProGen's deps
       nimble_options/ebin/
       ...
       my_actions/ebin/    # 3rd party lib
   ```

### Discovery

9. **Code path loading:** After `install`, the bootstrap module adds all
   `~/.config/pro_gen/deps/*/ebin` paths. The `ProGen.Actions` and
   `ProGen.Validations` registries auto-discover any `ProGen.Action.*` and
   `ProGen.Validate.*` modules loaded from these paths.

10. **Cache invalidation:** After `install`, clear the `:persistent_term` cache
    for action and validation registries so newly installed modules are
    discovered on next use.

### Idempotency and Error Handling

11. **Idempotent installs:** Skip deps already present and up-to-date. Update
    github deps if new commits exist. Re-fetch hex deps if version changed.

12. **Partial failure:** If a dependency fails to fetch or compile, log the
    error and continue with remaining deps. Return non-zero exit code if any
    failed. Print summary at end.

13. **Config validation:** Validate config structure: `libs:` must be a list,
    each entry needs `name:` and exactly one source key. Return clear errors.

## Acceptance Criteria

- `mix archive.install github andyl/pro_gen` installs the thin archive.
- Running `mix progen.action.list` outside a Mix project (after install) lists
  all built-in actions.
- `mix progen.install` with no config file installs ProGen itself and reports
  success.
- `mix progen.install` with a config containing a path dep creates a symlink.
- `mix progen.install` with a github dep clones the repo and compiles.
- After installing a lib with `ProGen.Action.Custom`, `mix progen.action.list`
  includes it.
- Running `install` twice skips already-installed deps.
- Invalid config produces a clear error and non-zero exit code.
- All CLI Core tasks work both as project dep and via global archive.

## Out of Scope

- Lock file or dependency resolution.
- Uninstall / upgrade commands (manual delete, re-run install).
- Private GitHub repos or authenticated Hex packages.
- Per-project lib configuration (global only).
- Git branch/tag selection for github deps (default branch only).
- TOML config format (YAML only).
