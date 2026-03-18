defmodule ProGen.Action.Test.ValidateFail do
  @moduledoc "Action with failing @validate (test fixture)"

  use ProGen.Action

  @validate [{"filesys", [:no_mix]}]

  @impl true
  def perform(_args) do
    Process.put(:validate_fail_performed, true)
    :ok
  end
end
