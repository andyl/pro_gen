defmodule ProGen.Action.Test.ConfirmPass do
  @moduledoc false

  use ProGen.Action

  @description "Action whose confirm/2 always passes (test fixture)"
  @option_schema [
    message: [type: :string, required: true, doc: "A message"]
  ]

  @impl true
  def perform(args), do: {:ok, Keyword.fetch!(args, :message)}

  @impl true
  def confirm(_result, _args), do: :ok
end
