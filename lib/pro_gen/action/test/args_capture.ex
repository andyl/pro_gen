defmodule ProGen.Action.Test.ArgsCapture do
  @moduledoc "Captures args to process dict (test fixture)"

  use ProGen.Action

  @opts_def [
    message: [type: :string, required: true, doc: "A message"]
  ]

  @impl true
  def perform(args) do
    Process.put(:captured_args, args)
    :ok
  end
end
