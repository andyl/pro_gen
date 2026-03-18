defmodule ProGen.Action.Igniter.Install do
  @moduledoc """
  Use igniter to install a dependency in your mix.exs file.
  """

  use ProGen.Action
  alias ProGen.Sys

  @opts_def [ dependency: [type: :string, required: true, doc: "The dependency to install"] ]
  @validate [{"filesys", [:has_mix, :has_git]}]

  @impl true
  def depends_on(_args), do: ["igniter_new.install"]

  @impl true
  def needed?(args) do
    Keyword.fetch!(args, :dependency)
    |> find_dep()
  end

  @impl true
  def perform(args) do
    dependency = Keyword.fetch!(args, :dependency)
    Sys.cmd("mix igniter.install #{dependency} --yes")
  end

  @impl true
  def confirm(_result, args) do
    dependency = Keyword.fetch!(args, :dependency)

    if File.dir?(dependency) do
      :ok
    else
      {:error, "dependency \"#{dependency}\" was not installed"}
    end
  end

  defp find_dep(_dep) do
    # check the Mix.exs file (in deps) to see if the dependency has been installed
    # there is a mix task (mix deps) that could be grepped...
    true
  end
end
