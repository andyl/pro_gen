defmodule ProGen.Operation.Run do
  @moduledoc """
  Runs a system command.
  """

  use ProGen.Operation

  @impl true
  def description do
    "Run a system command"
  end

  @impl true
  def option_schema do
    [
      command: [type: :string, required: true, doc: "The command to execute"],
      args: [type: {:list, :string}, default: [], doc: "Arguments to pass"],
      dir: [type: :string, default: ".", doc: "Working directory"]
    ]
  end

  @impl true
  def perform(args) do
    command = Keyword.fetch!(args, :command)
    cmd_args = Keyword.get(args, :args, [])
    dir = Keyword.get(args, :dir, ".")

    System.cmd(command, cmd_args, cd: dir)
  end
end
