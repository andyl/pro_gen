defmodule ProGen.Action.Test.CcDefault do
  @moduledoc "Test fixture without @commit_type (uses default)"

  use ProGen.Action

  @impl true
  def perform(_args), do: :ok
end
