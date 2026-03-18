defmodule ProGen.Action.Test.DepDiamond do
  @moduledoc "Diamond top depends on both branches (test fixture)"

  use ProGen.Action

  @opts_def []

  @impl true
  def depends_on(_args), do: ["test.dep_branch_a", "test.dep_branch_b"]

  @impl true
  def perform(_args) do
    {:ok, :diamond_ran}
  end
end
