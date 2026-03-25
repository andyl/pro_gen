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
    text = Keyword.fetch!(args, :message)
    IO.puts(text)
    :ok
  end
end
