defmodule ProGen.Action.Test.DepFailing do
  @moduledoc false

  use ProGen.Action

  @description "Always fails in confirm (test fixture)"
  @option_schema []

  @impl true
  def perform(_args), do: :ok

  @impl true
  def confirm(_result, _args), do: {:error, "I always fail"}
end
