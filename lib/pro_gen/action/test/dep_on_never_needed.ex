defmodule ProGen.Action.Test.DepOnNeverNeeded do
  @moduledoc false

  use ProGen.Action

  @description "Depends on never_needed to test force non-propagation (test fixture)"
  @option_schema [
    message: [type: :string, required: true, doc: "Passed to satisfy never_needed's schema"]
  ]

  @impl true
  def depends_on(args), do: [{"test.never_needed", [message: Keyword.get(args, :message, "x")]}]

  @impl true
  def perform(_args) do
    Process.put(:dep_on_never_needed_ran, true)
    {:ok, :dep_on_never_needed_ran}
  end
end
