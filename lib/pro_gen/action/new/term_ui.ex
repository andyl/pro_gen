defmodule ProGen.Action.New.TermUI do
  @moduledoc """
  Create a new TermUI application.

  Skips creation when the project directory already exists.
  Pass `force: true` to regenerate regardless.
  """

  use ProGen.Action
  alias ProGen.Xt.Sys, as: Sys

  @impl true
  def opts_def do
    [project: [type: :string, required: true, doc: "Name of the TermUI project to create"]]
  end

  @impl true
  def depends_on(_args) do
    [{"archive.install", package: "igniter_new"}]
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
    Sys.cmd("mix igniter.new #{project} --install term_ui")
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
