defmodule ProGen.Action.Tableau.Install do

  use ProGen.Action

  # arguments
  # - --force-latest - install latest version
  #
  #

  @description "Install tableau"

  # add an option for --force
  @option_schema []

  def needed?(_args) do
    # let
    # if --force == false,
    true
  end

  def perform(_args) do
    # if force_latest == true
    #   mix archive.install hex tableau_new --force
    # else
    #   mix archive.install hex tableau_new
    :ok
  end

  def confirm(_args) do
    :ok
  end

end
