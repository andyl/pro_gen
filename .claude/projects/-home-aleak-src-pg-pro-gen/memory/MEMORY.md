# ProGen Memory

## Repo Layout
- **pro_gen** (core library): `/home/aleak/src/pg/pro_gen`
- **pro_gen_cli** (CLI archive): `/home/aleak/src/pg/pro_gen_cli`
- Namespace split: `ProGen.*` in core, `ProGen.CLI.*` + `Mix.Tasks.Progen.*` in CLI
- CLI depends on core via `path: "../pro_gen"` for local dev

## Current State (2026-03-24)
- Core library is feature-complete: actions, validations, scripts, config, auto-commit, conventional commits
- CLI modules were implemented then removed from core (commit a079002) in prep for pro_gen_cli split
- pro_gen_cli repo created with 10 Mix tasks, shared CLI helpers
- Pending in pro_gen_cli: GlobalConfig (~/.config/pro_gen/config.yml), Bootstrap, Installer, 3rd-party lib support (Phases 2-7 of cli-extras plan)
