defmodule ProGen.Action.Test.DepCycleA do
  @moduledoc "Cycle A depends on cycle B (test fixture)"

  use ProGen.Action

  @impl true
  def depends_on(_args), do: ["test.dep_cycle_b"]

  @impl true
  def perform(_args), do: {:ok, :cycle_a}
end
