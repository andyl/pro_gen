defmodule ProGen.Action.Test.ConfirmOkOpts do
  @moduledoc "Action whose confirm/2 returns {:ok, []} with no cd (test fixture)"

  use ProGen.Action

  @impl true
  def opts_def do
    [message: [type: :string, required: true, doc: "A message"]]
  end

  @impl true
  def perform(args), do: {:ok, Keyword.fetch!(args, :message)}

  @impl true
  def confirm(_result, _args), do: {:ok, []}
end
