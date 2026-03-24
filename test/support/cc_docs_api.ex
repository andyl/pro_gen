defmodule ProGen.Action.Test.CcDocsApi do
  @moduledoc "Test fixture with scoped @commit_type docs(api)"

  use ProGen.Action

  @commit_type "docs(api)"

  @impl true
  def perform(_args), do: :ok
end
