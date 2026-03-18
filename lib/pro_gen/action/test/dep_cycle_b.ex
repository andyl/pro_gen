defmodule ProGen.Action.Test.DepCycleB do
  @moduledoc "Cycle B depends on cycle A (test fixture)"

  use ProGen.Action

  @option_schema []

  @impl true
  def depends_on(_args), do: ["test.dep_cycle_a"]

  @impl true
  def perform(_args), do: {:ok, :cycle_b}
end
