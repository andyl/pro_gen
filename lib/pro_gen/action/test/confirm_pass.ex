defmodule ProGen.Action.Test.ConfirmPass do
  @moduledoc "Action whose confirm/2 always passes (test fixture)"

  use ProGen.Action

  @opts_def [
    message: [type: :string, required: true, doc: "A message"]
  ]

  @impl true
  def perform(args), do: {:ok, Keyword.fetch!(args, :message)}

  @impl true
  def confirm(_result, _args), do: :ok
end
