defmodule ProGen.Action.Test.DepModFullOpts do
  @moduledoc "Depends on dep_with_opts using full module atom with opts (test fixture)"

  use ProGen.Action

  @impl true
  def depends_on(_args), do: [{ProGen.Action.Test.DepWithOpts, [message: "from_mod"]}]

  @impl true
  def perform(_args) do
    Process.put(:dep_mod_full_opts_ran, true)
    {:ok, :dep_mod_full_opts_ran}
  end
end
