defmodule ProGen.Action.Test.ArgsCapture do
  @moduledoc false

  use ProGen.Action

  @description "Captures args to process dict (test fixture)"
  @option_schema [
    message: [type: :string, required: true, doc: "A message"]
  ]

  @impl true
  def perform(args) do
    Process.put(:captured_args, args)
    :ok
  end
end
