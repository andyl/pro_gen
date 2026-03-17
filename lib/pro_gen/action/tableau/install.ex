defmodule ProGen.Action.Tableau.Install do

  use ProGen.Action

  # arguments
  # - --force - force installation of the latest version

  @description "Install tableau"

  # add an option for --
  @option_schema []

  def needed?(_args) do
    # TODO: implement this pseudo code
    # case {already_installed, force_option} do
    #   {true, false} -> false
    #   {true, true}  -> true
    #   {false, _  }  -> true
    # end

    true
  end

  def perform(_args) do
    ProGen.Sys.cmd("mix archive.install hex tableau_new --force")
    :ok
  end

  def confirm(_args) do
    # Add logic here to confirm that tableau_new is installed.
    # Maybe confirm by doing 'mix tableau.new --help'
    :ok
  end

end
