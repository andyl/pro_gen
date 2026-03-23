defmodule ProGen.Action.Docker.Build do
  @moduledoc """
  Create a Docker image.
  """

  use ProGen.Action
  alias ProGen.Sys

  @impl true
  def opts_def do
    [
      deps: [type: :string, required: true,  doc: "Space-separated list of dependencies to install"],
      args: [type: :string, required: false, doc: "Additional command-line flags (e.g. --auth-strategy password)"],
      only: [type: :string, required: false, doc: "Install in specific environments (e.g. dev,test)"]
    ]
  end

  @impl true
  def validate(_args) do
    [
      {"filesys", [:has_mix, :has_git, :has_docker, {:has_file, "Dockerfile"}]}
    ]
  end

  # @impl true
  # def depends_on(_args), do: [{"archive.install", package: "igniter_new"}]

  # @impl true
  # def needed?(args) do
  #   deps = parse_deps(args)
  #   Enum.any?(deps, fn dep -> not dep_installed?(dep) end)
  # end

  @impl true
  def perform(args) do
    project = args[:project]
    cmd = "docker build -t #{project} ."
    ProGen.Script.puts(cmd)
    Sys.cmd(cmd)
  end

  @impl true
  def confirm(_result, args) do
    project = args[:project]
    # this is example code - probably it fails
    # please replace with working code
    # maybe there is a better way to do this than "grep"
    cmd = "docker images | grep #{project}"
    ProGen.Script.puts(cmd)
    Sys.cmd(cmd)
  end

end
