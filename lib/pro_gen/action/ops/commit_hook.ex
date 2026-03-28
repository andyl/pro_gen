defmodule ProGen.Action.Ops.CommitHook do
  @moduledoc """
  Install a Conventional Commits git hook.

  Uses the `commit_hook` package to enforce Conventional Commits format
  on all commit messages.

  Learn more at [conventionalcommits.org](https://www.conventionalcommits.org).

  ## Dependencies

  Depends on `deps.install` to ensure the `commit_hook` package is in `mix.exs`.

  ## What it does

  Runs `mix commit_hooks.enable` to install a `commit-msg` git hook that
  validates commit messages against the Conventional Commits spec.

  ## Skipped when

  The action is skipped (`needed?/1` returns `false`) when the `commit_hook`
  dependency is installed and `.git/hooks/commit-msg` already exists. Pass
  `force: true` to run regardless.
  """

  use ProGen.Action
  alias ProGen.Xt.Sys, as: Sys

  @impl true
  def validate(_args), do: [{"filesys", [:has_mix, :has_git]}]

  @impl true
  def depends_on(_args) do
    [{"deps.install", deps: "commit_hook"}]
  end

  @impl true
  def needed?(_args) do
    not dep_installed?() or not File.exists?(".git/hooks/commit-msg")
  end

  @impl true
  def perform(_args) do
    Sys.cmd("pwd")
    Sys.cmd("mix commit_hook.enable")
    ProGen.Script.puts("Git hooks have been installed")
    ProGen.Script.puts("Conventional Commit messages are enforced")

    :ok
  end

  @impl true
  def confirm(_result, _args) do
    if File.exists?(".git/hooks/commit-msg") do
      :ok
    else
      {:error, ".git/hooks/commit-msg was not created"}
    end
  end

  # -----

  defp dep_installed? do
    case File.read("mix.exs") do
      {:ok, contents} -> String.contains?(contents, ":commit_hook")
      {:error, _} -> false
    end
  end
end
