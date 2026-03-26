# Composite Actions

## The Problem

Sometimes you want post-processing to happen automatically after an action
succeeds. For example, after generating a Phoenix project with `new.phoenix`,
you might want to configure `git_ops`, install a conventional-commit hook, or
run other setup actions. The question is: where does that orchestration live?

ProGen actions execute callbacks in a fixed order:

```
opts_def/0 → depends_on/1 → needed?/1 → validate/1 → perform/1 → confirm/2
```

`depends_on/1` runs **before** `perform/1`, so it handles prerequisites — not
follow-up work. `confirm/2` is a postcondition check, not a place for
side-effecting logic. That leaves two clean options: **composite actions** and
**scripts**.

## Composite Actions

A composite action is a thin wrapper action whose `perform/1` calls other
actions in sequence. It uses `depends_on/1` for prerequisites and
`ProGen.Actions.run/2` inside `perform/1` for the post-processing steps.

### Example

Suppose `new.phoenix` creates the project and `ops.git_ops` configures
git_ops. A composite action ties them together:

```elixir
defmodule ProGen.Action.New.PhoenixFull do
  @moduledoc """
  Generate a Phoenix project with full DevOps setup.

  Runs `new.phoenix`, then configures git_ops and installs a
  conventional-commit hook.
  """

  use ProGen.Action

  @impl true
  def opts_def do
    [
      project: [type: :string, required: true, doc: "Project name"],
      args:    [type: :string, required: false, doc: "Extra phx.new arguments"]
    ]
  end

  @impl true
  def depends_on(args) do
    # Prerequisites: create the Phoenix project first.
    [{"new.phoenix", Keyword.take(args, [:project, :args])}]
  end

  @impl true
  def needed?(args) do
    # Delegate to the same check as new.phoenix.
    project = Keyword.fetch!(args, :project)
    not File.dir?(project)
  end

  @impl true
  def perform(args) do
    project = Keyword.fetch!(args, :project)

    # Post-processing: run inside the new project directory.
    File.cd!(project, fn ->
      ProGen.Actions.run("ops.git_ops", [])
      ProGen.Actions.run("ops.conv_commit_hook", [])
    end)
  end
end
```

Usage:

```elixir
ProGen.Actions.run("new.phoenix_full", project: "my_app")
```

### How to Build a Composite Action

1. **Create a module** under `lib/pro_gen/action/` that does `use ProGen.Action`.
2. **Declare prerequisites** in `depends_on/1` — these are actions that must
   succeed before yours runs (e.g., `new.phoenix`).
3. **Call follow-up actions** inside `perform/1` using `ProGen.Actions.run/2`.
   These share the same idempotency set, so each action runs at most once per
   top-level call.
4. **Forward relevant options** — pass the subset of your args that each
   sub-action needs.
5. **Handle errors** — `ProGen.Actions.run/2` returns `{:ok, result}` or
   `{:error, reason}`. Decide whether a follow-up failure should fail the
   whole composite or just warn.

### Benefits

- **Declarative prerequisites** via `depends_on/1` — the framework handles
  ordering, idempotency, and cycle detection.
- **Explicit post-processing** — the follow-up steps are visible in
  `perform/1`, not hidden in another action's internals.
- **Reusable building blocks** — `new.phoenix`, `ops.git_ops`, and
  `ops.conv_commit_hook` remain independent actions that work on their own.
- **No framework changes** — composite actions use the existing callback
  contract.

## Script Alternative

If the post-processing varies by context — some Phoenix projects want
`git_ops`, others don't — a **Script** is a better fit. Scripts are plain
Elixir functions that orchestrate actions with arbitrary logic between them.

### Example

```elixir
#!/usr/bin/env elixir

Mix.install([{:pro_gen, path: "~/src/pro_gen"}])

alias ProGen.Script, as: PS

PS.cli_args(
  description: "Generate a Phoenix project with optional DevOps setup",
  args: [
    name: [value_name: "NAME", help: "Project name", required: true, parser: :string]
  ],
  flags: [
    git_ops:     [short: "-g", help: "Configure git_ops",               multiple: false],
    commit_hook: [short: "-c", help: "Install conventional-commit hook", multiple: false]
  ]
)

PS.parse_args()
args = ProGen.Script.Env.get(:pg_args)

# Core action — always runs
PS.action("Create Phoenix project", "new.phoenix", project: args.name)

# Conditional post-processing
if args.git_ops do
  PS.action("Configure git_ops", "ops.git_ops", [])
end

if args.commit_hook do
  PS.action("Install commit hook", "ops.conv_commit_hook", [])
end
```

### When to Use Which

| Situation | Use |
|---|---|
| Post-processing is always the same for this action | Composite action |
| Post-processing varies by caller or context | Script |
| You want the result discoverable via `ProGen.Actions.list_actions/0` | Composite action |
| You want a standalone CLI entry point | Script |
