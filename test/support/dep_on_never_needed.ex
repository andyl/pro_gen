defmodule ProGen.Action.Test.DepOnNeverNeeded do
  @moduledoc "Depends on never_needed to test force non-propagation (test fixture)"

  use ProGen.Action

  @impl true
  def opts_def do
    [message: [type: :string, required: true, doc: "Passed to satisfy never_needed's schema"]]
  end

  @impl true
  def depends_on(args), do: [{"test.never_needed", [message: Keyword.get(args, :message, "x")]}]

  @impl true
  def perform(_args) do
    Process.put(:dep_on_never_needed_ran, true)
    {:ok, :dep_on_never_needed_ran}
  end
end
