defmodule ProGen.Action.Test.DepWithOpts do
  @moduledoc "Captures args from dependency opts (test fixture)"

  use ProGen.Action

  @impl true
  def opts_def do
    [message: [type: :string, required: true, doc: "A message"]]
  end

  @impl true
  def perform(args) do
    Process.put(:dep_with_opts_args, args)
    {:ok, :dep_with_opts_ran}
  end
end
