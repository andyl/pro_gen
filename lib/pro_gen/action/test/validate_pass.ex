defmodule ProGen.Action.Test.ValidatePass do
  @moduledoc "Action with passing @validate (test fixture)"

  use ProGen.Action

  @validate [{"filesys", [:has_mix]}]

  @impl true
  def perform(_args), do: :ok
end
