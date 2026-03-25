defmodule ProGen.Action.New.Phoenix do
  @moduledoc """
  Create a new Phoenix application.

  Skips creation when the project directory already exists.
  Pass `force: true` to regenerate regardless.
  """

  use ProGen.Action
  alias ProGen.Sys

  @impl true
  def opts_def do
    [
      project: [type: :string, required: true,  doc: "Name of the phx project to create"],
      args:    [type: :string, required: false, doc: "Phx.new command line arguments"]
    ]
  end

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
  def perform(input_args) do
    project = Keyword.fetch!(input_args, :project)
    args    = Keyword.get(input_args, :args)
    Sys.cmd("rm -rf #{project}")

    argout = if args, do: "--with-args '#{args}'", else: ""

    cmd = "mix igniter.new #{project} --with=phx.new #{argout} --yes"
    ProGen.Script.puts(cmd |> ProGen.Xtool.StringUtil.compress())
    Sys.cmd(cmd)
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
