defmodule ProGen.Action.PhxNew do
  @moduledoc """
  Create a new Phoenix application.

  Skips creation when the project directory already exists.
  Pass `force: true` to regenerate regardless.
  """

  use ProGen.Action
  alias ProGen.Sys

  @opts_def [
    project: [type: :string, required: true, doc: "Name of the phx project to create"]
  ]

  @impl true
  def depends_on(_args) do
    [{"archive.install", package: "phx_new"}]
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
    Sys.cmd("mix igniter.new #{project} --with=phx.new --with-args '--template heex --css tailwind'")
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
