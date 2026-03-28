defmodule ProGen.Action.Test.DepModFull do
  @moduledoc "Depends on dep_base using full module atom (test fixture)"

  use ProGen.Action

  @impl true
  def depends_on(_args), do: [ProGen.Action.Test.DepBase]

  @impl true
  def perform(_args) do
    Process.put(:dep_mod_full_ran, true)
    {:ok, :dep_mod_full_ran}
  end
end
