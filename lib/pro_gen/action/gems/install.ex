defmodule ProGen.Action.Gems.Install do
  @moduledoc """
  Install a Ruby gem.
  """

  use ProGen.Action
  alias ProGen.Sys

  @impl true
  def opts_def do
    [
      gems: [type: :string, required: true,  doc: "Space-separated list of dependencies to install"],
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
    cmd = "mix igniter.install #{deps} #{args_str} #{only_str} --yes" |> ProGen.Util.compress()
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
    case File.read("mix.exs") do
      {:ok, contents} -> String.contains?(contents, ":#{dep}")
      {:error, _} -> false
    end
  end
end
