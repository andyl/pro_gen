defmodule ProGen.Action.Ops.CommitHook do
  @moduledoc """
  Install a Conventional Commits git hook.

  # TODO: finish documentation
  """

  use ProGen.Action
  alias ProGen.Xt.Sys, as: Sys

  @impl true
  def validate(_args), do: [{"filesys", [:has_mix, :has_git]}]

  @impl true
  def depends_on(_args) do
    [{"deps.install", "commit_hook"}]
  end

  @impl true
  def needed?(_args) do
    # TODO: needed if
    # commit_hook dep is missing OR not (File.exists?(".git/hooks/commit-msg"))
  end

  @impl true
  def perform(_args) do
    Sys.cmd("mix commit_hooks.enable")
    ProGen.Script.puts("Git hooks have been installed")
    ProGen.Script.puts("Conventional Commit messages are enforced")

    :ok
  end

  @impl true
  def confirm(_result, _args) do
    # TODO: add logic for this function
  end
end
