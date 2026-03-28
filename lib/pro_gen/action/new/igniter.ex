defmodule ProGen.Action.New.Igniter do
  @moduledoc """
  Create a new elixir application with Igniter.

  Skips creation when the project directory already exists.
  Pass `force: true` to regenerate regardless.
  """

  use ProGen.Action
  alias ProGen.Xt.Sys, as: Sys

  @impl true
  def opts_def do
    [
      project: [type: :string, required: true, doc: "Name of the igniter project to create"],
      packages: [type: :string, required: false, doc: "Comma-seperated list of packages to install"]
    ]
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

    # packages = case Keyword.fetch!(args, :packages) do
    packages = case args[:packages] do
      nil -> ""
      string -> "--install " <> string
    end

    cmd = "mix igniter.new #{project} #{packages}"
    ProGen.Script.puts(cmd)
    Sys.cmd("mix igniter.new #{project} #{packages}")
  end

  @impl true
  def confirm(_result, args) do
    project = Keyword.fetch!(args, :project)

    if File.dir?(project) do
      {:ok, cd: Path.expand(project)}
    else
      {:error, "project directory \"#{project}\" was not created"}
    end
  end
end
