defmodule ProGen.Action.Test.ValidateSkip do
  @moduledoc "Action with failing validate/1 but needed?/1 returns false (test fixture)"

  use ProGen.Action

  @impl true
  def validate(_args), do: [{"filesys", [:no_mix]}]

  @impl true
  def needed?(_args), do: false

  @impl true
  def perform(_args), do: :ok
end
