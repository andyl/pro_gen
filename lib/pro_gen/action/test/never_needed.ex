defmodule ProGen.Action.Test.NeverNeeded do
  @moduledoc false

  use ProGen.Action

  @description "Action that is never needed (test fixture)"
  @option_schema [
    message: [type: :string, required: true, doc: "A message"]
  ]

  @impl true
  def needed?(_args), do: false

  @impl true
  def perform(_args), do: :ok
end
