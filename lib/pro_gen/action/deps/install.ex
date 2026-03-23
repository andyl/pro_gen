defmodule ProGen.Action.Deps.Install do
  @moduledoc """
  Use igniter to install a dependency in your mix.exs file.
  """

  use ProGen.Action
  alias ProGen.Sys

  @impl true
  def opts_def do
    [
      dep:  [type: :string, required: true,  doc: "The dependency to install"],
      only: [type: :string, required: false, doc: "Install in specific environments"]
    ]
  end

  @impl true
  def validate(_args), do: [{"filesys", [:has_mix, :has_git]}]

  @impl true
  def depends_on(_args), do: [{"archive.install", package: "igniter_new"}]

  @impl true
  def needed?(args) do
    dep = Keyword.fetch!(args, :dep)
    not find_dep(dep)
  end

  @impl true
  def perform(args) do
    only = Keyword.get(args, :only)
    dependency = Keyword.fetch!(args, :dep)
    only_str   = if only, do: "--only #{only}", else: ""
    cmd = "mix igniter.install #{dependency} #{only_str} --yes"
    ProGen.Script.puts(cmd |> ProGen.Util.compress())
    Sys.cmd(cmd)
  end

  @impl true
  def confirm(_result, args) do
    dep = Keyword.fetch!(args, :dep)

    if find_dep(dep) do
      :ok
    else
      {:error, "dependency \"#{dep}\" was not installed"}
    end
  end

  # -----

  defp find_dep(dep) do
    case File.read("mix.exs") do
      {:ok, contents} -> String.contains?(contents, ":#{dep}")
      {:error, _} -> false
    end
  end
end
