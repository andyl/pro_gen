defmodule ProGen.Action.Test.ValidateFail do
  @moduledoc "Action with failing validate/1 (test fixture)"

  use ProGen.Action

  @impl true
  def validate(_args), do: [{"filesys", [:no_mix]}]

  @impl true
  def perform(_args) do
    Process.put(:validate_fail_performed, true)
    :ok
  end
end
