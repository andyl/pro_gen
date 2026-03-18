defmodule ProGen.Action.Test.Echo2 do
  @moduledoc """
  Echo a message to stdout.
  """

  use ProGen.Action

  @opts_def [
    message: [type: :string, required: true, doc: "The message to print"]
  ]

  @impl true
  def perform(args) do
    IO.puts("Test.Echo2")
    args |> Keyword.fetch!(:message) |> IO.puts()
    :ok
  end
end
