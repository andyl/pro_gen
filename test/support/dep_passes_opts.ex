defmodule ProGen.Action.Test.DepPassesOpts do
  @moduledoc "Depends on dep_with_opts with specific options (test fixture)"

  use ProGen.Action

  @impl true
  def depends_on(_args), do: [{"test.dep_with_opts", [message: "from_parent"]}]

  @impl true
  def perform(_args) do
    {:ok, :dep_passes_opts_ran}
  end
end
