defmodule ProGen.Action.Tableau.New do

  use ProGen.Action
  alias ProGen.Sys

  @description "Create a new Tableau application"
  @option_schema []

  # QUESTION:
  # I'd like this task to depend on ProGen.Action.Tableau.Install
  # - should I make a "depends_on" module attribute?
  # - or a 'depends_on' behavior?

  def needed?(_args) do
    # check to see if the directory #{project} already exists.
    true
  end

  def perform(_args) do
    cmd = "mix tableau.new #{project} --template heex --css tailwind"
    Sys.cmd(cmd)
    :ok
  end

  def confirm(_args) do
    # check to see if the directory #{project} exists (if so :ok)
    :ok
  end

end
