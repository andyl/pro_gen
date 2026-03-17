defmodule ProGen.Action.Tableau.New do
  @moduledoc """
  Creates a new Tableau application using the `tableau_new` Mix archive.

  Skips creation when the project directory already exists.
  Pass `force: true` to regenerate regardless.
  """

  use ProGen.Action
  alias ProGen.Sys

  @description "Create a new Tableau application"
  @option_schema [
    project: [type: :string, required: true, doc: "Name of the Tableau project to create"]
  ]

  @impl true
  def needed?(args) do
    project = Keyword.fetch!(args, :project)
    not File.dir?(project)
  end

  @impl true
  def perform(args) do
    project = Keyword.fetch!(args, :project)
    Sys.cmd("rm -rf #{project}")
    Sys.cmd("mix tableau.new #{project} --template heex --css tailwind")
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
