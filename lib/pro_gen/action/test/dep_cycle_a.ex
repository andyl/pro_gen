defmodule ProGen.Action.Test.DepCycleA do
  @moduledoc false

  use ProGen.Action

  @description "Cycle A depends on cycle B (test fixture)"
  @option_schema []

  @impl true
  def depends_on(_args), do: ["test.dep_cycle_b"]

  @impl true
  def perform(_args), do: {:ok, :cycle_a}
end
