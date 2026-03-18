defmodule ProGen.Action.Run do
  @moduledoc """
  Run a system command.
  """

  use ProGen.Action

  @opts_def [
    command: [type: :string, required: true, doc: "The command to execute"],
    args: [type: {:list, :string}, default: [], doc: "Arguments to pass"],
    dir: [type: :string, default: ".", doc: "Working directory"]
  ]

  @impl true
  def perform(args) do
    command = Keyword.fetch!(args, :command)
    cmd_args = Keyword.get(args, :args, [])
    dir = Keyword.get(args, :dir, ".")

    System.cmd(command, cmd_args, cd: dir)
  end
end
