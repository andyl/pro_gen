defmodule ProGen.Action.Test.DepConditional do
  @moduledoc false

  use ProGen.Action

  @description "Conditionally depends on dep_base (test fixture)"
  @option_schema [
    with_dep: [type: :boolean, default: false, doc: "Whether to include dependency"]
  ]

  @impl true
  def depends_on(args) do
    if Keyword.get(args, :with_dep, false) do
      ["test.dep_base"]
    else
      []
    end
  end

  @impl true
  def perform(_args) do
    Process.put(:dep_conditional_ran, true)
    {:ok, :dep_conditional_ran}
  end
end
