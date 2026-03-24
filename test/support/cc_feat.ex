defmodule ProGen.Action.Test.CcFeat do
  @moduledoc "Test fixture with custom @commit_type feat"

  use ProGen.Action

  @commit_type "feat"

  @impl true
  def perform(_args), do: :ok
end
