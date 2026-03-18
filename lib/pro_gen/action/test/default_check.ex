defmodule ProGen.Action.Test.DefaultCheck do
  @moduledoc "Checks defaults in needed?/1 (test fixture)"

  use ProGen.Action

  @opts_def [
    label: [type: :string, default: "default_value", doc: "A label"]
  ]

  @impl true
  def needed?(args) do
    Process.put(:needed_args, args)
    true
  end

  @impl true
  def perform(_args), do: :ok
end
