defmodule ProGen.Action.Test.DepOnFailing do
  @moduledoc false

  use ProGen.Action

  @description "Depends on dep_failing (test fixture)"
  @option_schema []

  @impl true
  def depends_on(_args), do: ["test.dep_failing"]

  @impl true
  def perform(_args) do
    Process.put(:dep_on_failing_ran, true)
    {:ok, :should_not_run}
  end
end
