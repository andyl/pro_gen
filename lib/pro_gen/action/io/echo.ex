defmodule ProGen.Action.IO.Echo do
  @moduledoc """
  Echo a message to stdout.
  """

  use ProGen.Action

  @impl true
  def opts_def do
    [message: [type: :string, required: true, doc: "The message to print"]]
  end

  @impl true
  def perform(args) do
    args |> Keyword.fetch!(:message) |> IO.puts()
    :ok
  end
end
