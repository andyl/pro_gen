defmodule ProGen.Action.Git.Init do
  @moduledoc """
  Initialize a git repository.
  """

  use ProGen.Action

  @impl true
  def needed?(_args) do
    File.dir?(".git")
    |> Kernel.not()
  end

  @impl true
  def perform(_args) do
    ProGen.Xt.Sys.cmd("git", ["init"])
  end

  @impl true
  def confirm(_result, _args) do
    if File.dir?(".git"), do: :ok, else: {:error, ".git directory was not created"}
  end
end
