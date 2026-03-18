defmodule ProGen.Action.MixCompletions.Run do
  @moduledoc """
  Run mix completions

  Skips creation when the project directory already exists.
  Pass `force: true` to regenerate regardless.
  """

  use ProGen.Action
  alias ProGen.Sys

  @opts_def []

  @impl true
  def depends_on(_args), do: ["igniter_new.install"]

  @impl true
  def needed?(args) do
    project = Keyword.fetch!(args, :project)
    not File.dir?(project)
  end

  @impl true
  def perform(args) do
    project = Keyword.fetch!(args, :project)
    Sys.cmd("rm -rf #{project}")
    case Keyword.fetch!(args, :installs) do
      nil ->
        Sys.cmd("mix igniter.new #{project}")
      packages ->
        Sys.cmd("mix igniter.new #{project} --install #{packages}")
    end
  end

  @impl true
  def confirm(_result, args) do
    project = Keyword.fetch!(args, :project)

    if File.dir?(project) do
      :ok
    else
      {:error, "project directory \"#{project}\" was not created"}
    end
  end
end
