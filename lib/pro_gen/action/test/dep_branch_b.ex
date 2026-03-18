defmodule ProGen.Action.Test.DepBranchB do
  @moduledoc "Branch B depends on dep_base (test fixture)"

  use ProGen.Action

  @option_schema []

  @impl true
  def depends_on(_args), do: ["test.dep_base"]

  @impl true
  def perform(_args) do
    {:ok, :branch_b_ran}
  end
end
