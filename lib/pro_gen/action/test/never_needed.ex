defmodule ProGen.Action.Test.NeverNeeded do
  @moduledoc "Action that is never needed (test fixture)"

  use ProGen.Action

  @opts_def [
    message: [type: :string, required: true, doc: "A message"]
  ]

  @impl true
  def needed?(_args), do: false

  @impl true
  def perform(_args), do: :ok
end
