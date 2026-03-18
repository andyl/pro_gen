defmodule ProGen.Action.Echo do
  @moduledoc """
  Echo a message to stdout.
  """

  use ProGen.Action

  @opts_def [
    message: [type: :string, required: true, doc: "The message to print"]
  ]

  @impl true
  def perform(args) do
    args |> Keyword.fetch!(:message) |> IO.puts()
    :ok
  end
end
