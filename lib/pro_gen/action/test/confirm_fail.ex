defmodule ProGen.Action.Test.ConfirmFail do
  @moduledoc "Action whose confirm/2 always fails (test fixture)"

  use ProGen.Action

  @option_schema [
    message: [type: :string, required: true, doc: "A message"]
  ]

  @impl true
  def perform(args), do: {:ok, Keyword.fetch!(args, :message)}

  @impl true
  def confirm(_result, _args), do: {:error, "boom"}
end
