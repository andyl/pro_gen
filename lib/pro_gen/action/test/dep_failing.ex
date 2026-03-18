defmodule ProGen.Action.Test.DepFailing do
  @moduledoc "Always fails in confirm (test fixture)"

  use ProGen.Action

  @option_schema []

  @impl true
  def perform(_args), do: :ok

  @impl true
  def confirm(_result, _args), do: {:error, "I always fail"}
end
