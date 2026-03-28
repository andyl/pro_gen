defmodule ProGen.Action.Test.DepModShort do
  @moduledoc "Depends on dep_base using short module atom (test fixture)"

  use ProGen.Action

  @impl true
  def depends_on(_args), do: [Test.DepBase]

  @impl true
  def perform(_args) do
    Process.put(:dep_mod_short_ran, true)
    {:ok, :dep_mod_short_ran}
  end
end
