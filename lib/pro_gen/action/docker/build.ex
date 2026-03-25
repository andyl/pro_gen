defmodule ProGen.Action.Docker.Build do
  @moduledoc """
  Create a Docker image.
  """

  use ProGen.Action
  alias ProGen.Xt.Sys, as: Sys

  @impl true
  def opts_def do
    [
      project: [type: :string, required: true, doc: "Docker image tag / project name"],
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
    project = Keyword.fetch!(args, :project)

    case System.cmd("docker", ["images", "-q", project], stderr_to_stdout: true) do
      {output, 0} ->
        if String.trim(output) != "" do
          :ok
        else
          {:error, "docker image '#{project}' not found after build"}
        end

      {_, _code} ->
        {:error, "failed to verify docker image '#{project}'"}
    end
  end

end
