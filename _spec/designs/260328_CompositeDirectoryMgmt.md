# Design: Working Directory Management for Composite Actions

## Context

ProGen actions are composable via `depends_on/1`. Some actions (e.g.,
`new.phoenix`) create a project directory, while follow-on actions (`git.init`,
`deps.install`) must run inside it. Today there is no mechanism for an action
to tell the runner "I created a directory — cd there for what comes next."

## Design

Extend `confirm/2` to optionally return `{:ok, cd: path}` alongside the
existing `:ok` and `{:error, reason}`. The **runner** is responsible for
calling `File.cd!/1` — follow-on actions don't need to know anything about
directory changes beyond their existing validations (`:has_mix`, `:has_git`,
etc.).

### confirm/2 return values

```elixir
:ok                     # no change (today's default)
{:ok, cd: "/tmp/app"}   # tells runner to cd after this action
{:error, reason}        # confirmation failure
```

### Runner behavior (in `perform_and_confirm/2`)

```elixir
defp perform_and_confirm(mod, validated_args) do
  result = mod.perform(validated_args)

  case mod.confirm(result, validated_args) do
    :ok ->
      result

    {:ok, opts} when is_list(opts) ->
      if dir = opts[:cd], do: File.cd!(dir)
      result

    {:error, reason} ->
      {:error, {:confirmation_failed, reason}}
  end
end
```

### Example: new.phoenix action

```elixir
def confirm({:ok, _}, args) do
  project_dir = Path.expand(args[:project])
  if File.dir?(project_dir), do: {:ok, cd: project_dir}, else: {:error, "project dir not created"}
end
def confirm({:error, reason}, _args), do: {:error, reason}
```

Follow-on actions like `git.init` remain unchanged — the runner has already
cd'd into the project directory before they execute.

## Files to modify

1. **`lib/pro_gen/action.ex`** — update `@callback confirm` typespec to include `{:ok, keyword()}` return; update `@moduledoc` to document the new variant
2. **`lib/pro_gen/actions.ex`** — update `perform_and_confirm/2` to handle `{:ok, opts}` and apply `:cd`
3. **`lib/pro_gen/action/new/phoenix.ex`** — add `confirm/2` that returns `{:ok, cd: project_dir}` (reference implementation)
4. **Other `new.*` actions** (`tableau.ex`, `term_ui.ex`, `igniter.ex`) — same pattern as phoenix

## Files unchanged

- All non-project-creating actions — their default `confirm/2` returns `:ok`
- `lib/pro_gen/script.ex` — continues to work as-is
- Validation system — unchanged

## Verification

1. `mix test` — all existing tests pass (backward compat, default confirm still returns `:ok`)
2. New test: confirm returning `{:ok, cd: path}` causes runner to change working directory
3. New test: action depending on `new.phoenix` runs in the created project directory
4. New test: confirm returning `:ok` (no cd) leaves directory unchanged
