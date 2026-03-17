defmodule ProGen.Action.Test.DepWithOpts do
  @moduledoc false

  use ProGen.Action

  @description "Captures args from dependency opts (test fixture)"
  @option_schema [
    message: [type: :string, required: true, doc: "A message"]
  ]

  @impl true
  def perform(args) do
    Process.put(:dep_with_opts_args, args)
    {:ok, :dep_with_opts_ran}
  end
end
