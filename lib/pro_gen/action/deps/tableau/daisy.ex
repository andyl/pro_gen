defmodule ProGen.Action.Deps.Tableau.Daisy do
  @moduledoc """
  Setup Daisy for a Tableau project.

  Skips installation when the archive is already present.
  Pass `force: true` to reinstall regardless.
  """

  use ProGen.Action

  alias ProGen.CodeMods.File

  @css_file "assets/css/site.css"

  @validate [
    {"filesys", [:has_mix, {:has_file, @css_file}]},
    {"mix",     [{:has_dep,  "tableau"}]},
    {"lang",    [:has_npm]},
  ]

  @impl true
  def depends_on(_args) do
    [
      {"npm.install", [package: "daisy@latest"]},
    ]
  end

  # @impl true
  # def needed?(_args) do
  #   not File.exists?("RULES.md")
  # end

  @impl true
  def perform(_args) do
    # add CSS plugin
    File.append_line(@css_file, ~s(@plugin "daisyui"))
    # update CSS file
    File.sed_file(@css_file, ~s(s/\"$/\";/))
    :ok
  end

  @impl true
  def confirm(_result, _args) do
    :ok
  end

end

