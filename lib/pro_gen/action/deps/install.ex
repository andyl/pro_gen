defmodule ProGen.Action.Deps.Install do
  @moduledoc """
  Use igniter to install a dependency in your mix.exs file.
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
  def validate(_args), do: [{"filesys", [:has_mix, :has_git]}]

  @impl true
  def depends_on(_args), do: [{"archive.install", package: "igniter_new"}]

  @impl true
  def needed?(args) do
    deps = parse_deps(args)
    Enum.any?(deps, fn dep -> not dep_installed?(dep) end)
  end

  @impl true
  def perform(args) do
    deps = Keyword.fetch!(args, :deps)
    args_str = Keyword.get(args, :args, "")
    only_str = case Keyword.get(args, :only) do
      nil  -> ""
      only -> "--only #{only}"
    end
    cmd = "mix igniter.install #{deps} #{args_str} #{only_str} --yes" |> ProGen.Xt.StringUtil.compress()
    ProGen.Script.puts(cmd)
    Sys.cmd(cmd)
  end

  @impl true
  def confirm(_result, args) do
    deps = parse_deps(args)
    missing = Enum.reject(deps, &dep_installed?/1)

    case missing do
      [] -> :ok
      _  -> {:error, "dependencies not installed: #{Enum.join(missing, ", ")}"}
    end
  end

  # -----

  defp parse_deps(args) do
    args |> Keyword.fetch!(:deps) |> String.split()
  end

  defp dep_installed?(dep) do
    [kdep | _] = String.split(dep, "@")
    case File.read("mix.exs") do
      {:ok, contents} -> String.contains?(contents, ":#{kdep}")
      {:error, _} -> false
    end
  end
end
