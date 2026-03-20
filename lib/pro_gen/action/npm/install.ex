defmodule ProGen.Action.Npm.Install do
  @moduledoc """
  Use npm to install a package in your Elixir project.
  """

  use ProGen.Action
  alias ProGen.Sys

  @opts_def [ package: [type: :string, required: true, doc: "The npm package to install"] ]
  @validate [
    {"lang", [:has_npm]},
    {"filesys", [:has_mix, :has_git]}
  ]

  # @impl true
  # def depends_on(_args), do: [{"archive.install", package: "igniter_new"}]

  @impl true
  def needed?(args) do
    pkg = Keyword.fetch!(args, :package)
    not find_pkg(pkg)
  end

  @impl true
  def perform(args) do
    package = Keyword.fetch!(args, :package)
    Sys.cmd("npm i -D #{package}")
  end

  @impl true
  def confirm(_result, args) do
    pkg = Keyword.fetch!(args, :package)

    if find_pkg(pkg) do
      :ok
    else
      {:error, "npm package '#{pkg}' was not installed"}
    end
  end

  defp find_pkg(_pkg) do
    # TBD
    true
  end
end
