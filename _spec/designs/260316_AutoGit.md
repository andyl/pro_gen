# Auto Git

Auto Git Commit Per Step

## Problem

Make rollback easier by committing after every successful `command/2` or
`action/3` call in `ProGen.Script`.

## Decision

- Auto-commit after every successful `command/2` and `action/3` invocation
- Commit message = the description string (first argument to the function)
- Default: `commit: true`
- Opt-out: pass `commit: false` per call

## Details

- **Skip if no .git** — if .git is not present (not an error)
- **Skip on clean tree** — if no files changed, no-op (not an error)
- **Prefix commit messages** — e.g. `"[ProGen] Install Phoenix"` for easy
    identification and squashing
- **Opt-out per call:**
  ```elixir
  command("Fetch deps", "mix deps.get", commit: false)
  action("Add route", "route.add", [path: "/foo"], commit: false)
  ```
- At end of script, commits can be squashed into one if granular history isn't
  wanted

## Remove Git Functions

In the module ProGen.Script, remove these functions:
- git 
- commit 

## New Actions

Add these Actions:

- ProGen.Action.Git.Init:
    * needed? | return false if .git already exists (not an error)
    * perform | run 'git init'
    * confirm | .git directory exists 
- ProGen.Action.Git.Commit:
    * needed? | return false if no files changed (not an error)
    * perform | run "git add . ; git commit -am'<msg>'" 
    * confirm | commit successful 

