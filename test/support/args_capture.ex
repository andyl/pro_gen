defmodule ProGen.Action.Test.ArgsCapture do
  @moduledoc "Captures args to process dict (test fixture)"

  use ProGen.Action

  @impl true
  def opts_def do
    [message: [type: :string, required: true, doc: "A message"]]
  end

  @impl true
  def perform(args) do
    Process.put(:captured_args, args)
    :ok
  end
end
