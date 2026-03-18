defmodule ProGen.Action.Test.DepChild do
  @moduledoc "Child that depends on dep_base (test fixture)"

  use ProGen.Action

  @opts_def []

  @impl true
  def depends_on(_args), do: ["test.dep_base"]

  @impl true
  def perform(_args) do
    Process.put(:dep_child_ran, true)
    {:ok, :dep_child_ran}
  end
end
