defmodule ProGen.Action.New.Tableau do
  @moduledoc """
  Create a new Tableau application.

  Skips creation when the project directory already exists.
  Pass `force: true` to regenerate regardless.
  """

  use ProGen.Action
  alias ProGen.Xt.Sys, as: Sys

  @impl true
  def opts_def do
    [project: [type: :string, required: true, doc: "Name of the Tableau project to create"]]
  end

  @impl true
  def depends_on(_args) do
    [{"archive.install", package: "tableau_new"}]
  end

  @impl true
  def needed?(args) do
    project = Keyword.fetch!(args, :project)
    not File.dir?(project)
  end

  @impl true
  def perform(args) do
    project = Keyword.fetch!(args, :project)
    Sys.cmd("rm -rf #{project}")

    arg =
      "mix igniter.new #{project} --with=tableau.new --with-args '--template heex --css tailwind'"

    Sys.cmd(arg)
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
