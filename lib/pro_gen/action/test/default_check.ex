defmodule ProGen.Action.Test.DefaultCheck do
  @moduledoc false

  use ProGen.Action

  @description "Checks defaults in needed?/1 (test fixture)"
  @option_schema [
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
