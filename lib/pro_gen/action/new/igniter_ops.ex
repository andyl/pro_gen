defmodule ProGen.Action.New.IgniterOps do
  @moduledoc """
  Create a new elixir application with Igniter.

  Skips creation when the project directory already exists.
  Pass `force: true` to regenerate regardless.
  """

  use ProGen.Action
  # alias ProGen.Xt.Sys, as: Sys

  @impl true
  def opts_def do
    [
      project: [type: :string, required: true, doc: "Name of the igniter project to create"],
      packages: [type: :string, required: false, doc: "Comma-seperated list of packages to install"]
    ]
  end

  @impl true
  def depends_on(args) do
    [
      {"new.igniter", args},
      {"ops.git_ops", args},
      {"ops.commit_hook", args}
    ]
  end

  # @impl true
  # def needed?(args) do
  #   project = Keyword.fetch!(args, :project)
  #   not File.dir?(project)
  # end

  @impl true
  def perform(_args) do
    :ok
  end

  # @impl true
  # def confirm(_result, args) do
  #   project = Keyword.fetch!(args, :project)
  #
  #   if File.dir?(project) do
  #     :ok
  #   else
  #     {:error, "project directory \"#{project}\" was not created"}
  #   end
  # end
end
