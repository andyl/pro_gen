defmodule ProGen.Action.Igniter.Install do
  @moduledoc """
  Create a new Phoenix application.
  """

  use ProGen.Action
  alias ProGen.Sys

  @option_schema [
    dependency: [type: :string, required: true, doc: "The dependency to install"]
  ]

  @impl true
  def depends_on(_args), do: ["igniter_new.install"]

  @impl true
  def needed?(args) do
    # check the Mix.exs file (in deps) to see if the dependency has been installed
    # there is a mix task (mix deps) that could be grepped...
    true
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
