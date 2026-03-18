defmodule ProGen.Action.Igniter.Install do
  @moduledoc """
  Use igniter to install a dependency in your mix.exs file.
  """

  use ProGen.Action
  alias ProGen.Sys

  @opts_def [ dependency: [type: :string, required: true, doc: "The dependency to install"] ]
  # @validate [{"filesys", [:has_mix, :has_git]}]
  #
  # @impl true
  # def depends_on(_args), do: ["igniter_new.install"]

  @impl true
  def needed?(args) do
    dep = Keyword.fetch!(args, :dependency)
    not find_dep(dep)
  end

  @impl true
  def perform(args) do
    dependency = Keyword.fetch!(args, :dependency)
    Sys.cmd("mix igniter.install #{dependency} --yes")
  end

  @impl true
  def confirm(_result, args) do
    dep = Keyword.fetch!(args, :dependency)

    if find_dep(dep) do
      :ok
    else
      {:error, "dependency \"#{dep}\" was not installed"}
    end
  end

  defp find_dep(dep) do
    case File.read("mix.exs") do
      {:ok, contents} -> String.contains?(contents, ":#{dep}")
      {:error, _} -> false
    end
  end
end
