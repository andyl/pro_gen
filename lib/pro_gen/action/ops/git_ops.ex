defmodule ProGen.Action.Ops.GitOps do
  @moduledoc """
  Setup GitOps for automated changelog and version management.

  Learn more about GitOps config on the README.

  https://github.com/zachdaniel/git_ops#configuration

  ## Dependencies

  Depends on `deps.install` to ensure the `git_ops` package is in `mix.exs`.

  ## What it does

  1. Patches `config/config.exs` via `ProGen.Patch.Pkg.GitOps` (disables
     GitHub handle lookup).
  2. Runs `mix git_ops.release --initial` to create the first changelog
     and version tag.

  ## Skipped when

  The action is skipped (`needed?/1` returns `false`) when the git_ops
  config is already present in `config/config.exs`. Pass `force: true`
  to run regardless.
  """

  use ProGen.Action

  @impl true
  def validate(_args), do: [{"filesys", [:has_git, :has_mix]}]

  @impl true
  def depends_on(_args) do
    [{"deps.install", "git_ops"}]
  end

  @impl true
  def needed?(_args) do
    case File.read("config/config.exs") do
      {:ok, contents} -> not String.contains?(contents, ":git_ops")
      {:error, _} -> true
    end
  end

  @impl true
  def perform(_args) do
    # this is idempotent...
    ProGen.Patch.Pkg.GitOps.update_git_ops_config()
    # initial sync
    ProGen.Xt.Sys.cmd("mix git_ops.release --initial")
    ProGen.Script.puts("Initial release successful - git tag created")
    ProGen.Script.puts("Use 'git push --follow-tags' to push tags")
    :ok
  end

  @impl true
  def confirm(_result, _args) do
    {tags, 0} = System.cmd("git", ["tag", "--list"])

    if String.trim(tags) == "" do
      {:error, "no git tags found — initial release may have failed"}
    else
      :ok
    end
  end
end
