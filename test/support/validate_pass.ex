defmodule ProGen.Action.Test.ValidatePass do
  @moduledoc "Action with passing validate/1 (test fixture)"

  use ProGen.Action

  @impl true
  def validate(_args), do: [{"filesys", [:has_mix]}]

  @impl true
  def perform(_args), do: :ok
end
