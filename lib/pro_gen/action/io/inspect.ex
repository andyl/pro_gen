defmodule ProGen.Action.IO.Inspect do
  @moduledoc """
  Inspect an Elixir term to stdout.
  """

  use ProGen.Action

  @opts_def [
    element: [type: :any, required: true, doc: "The Elixir term to inspect"]
  ]

  @impl true
  def perform(args) do
    args |> Keyword.fetch!(:element) |> IO.inspect()
    :ok
  end
end
