defmodule ProGen.Action.Echo do
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
    args |> Keyword.fetch!(:message) |> IO.puts()
    :ok
  end
end
