defmodule ProGen.Action.Test.DepWithOpts do
  @moduledoc "Captures args from dependency opts (test fixture)"

  use ProGen.Action

  @opts_def [
    message: [type: :string, required: true, doc: "A message"]
  ]

  @impl true
  def perform(args) do
    Process.put(:dep_with_opts_args, args)
    {:ok, :dep_with_opts_ran}
  end
end
