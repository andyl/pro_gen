defmodule ProGen.Action.Igniter.Install do
  @moduledoc """
  Create a new Phoenix application.
  """

  use ProGen.Action
  alias ProGen.Sys

  @option_schema [
    project: [type: :string, required: true, doc: "Name of the phx project to create"]
  ]

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
