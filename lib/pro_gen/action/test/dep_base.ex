defmodule ProGen.Action.Test.DepBase do
  @moduledoc false

  use ProGen.Action

  @description "Base dependency action (test fixture)"
  @option_schema []

  @impl true
  def perform(_args) do
    count = Process.get(:dep_base_count, 0)
    Process.put(:dep_base_count, count + 1)
    {:ok, :dep_base_ran}
  end
end
