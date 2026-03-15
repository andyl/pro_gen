defmodule ProGen.Action.Test.Echo2 do
  @moduledoc """
  Echoes a message to stdout.
  """

  use ProGen.Action

  @description "Echo a message to stdout"
  @option_schema [
    message: [type: :string, required: true, doc: "The message to print"]
  ]

  @impl true
  def perform(args) do
    IO.puts("Test.Echo2")
    args |> Keyword.fetch!(:message) |> IO.puts()
    :ok
  end
end
