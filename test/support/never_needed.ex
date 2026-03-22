defmodule ProGen.Action.Test.NeverNeeded do
  @moduledoc "Action that is never needed (test fixture)"

  use ProGen.Action

  @impl true
  def opts_def do
    [message: [type: :string, required: true, doc: "A message"]]
  end

  @impl true
  def needed?(_args), do: false

  @impl true
  def perform(_args), do: :ok
end
