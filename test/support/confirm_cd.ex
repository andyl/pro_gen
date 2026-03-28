defmodule ProGen.Action.Test.ConfirmCd do
  @moduledoc "Action whose confirm/2 returns {:ok, cd: path} (test fixture)"

  use ProGen.Action

  @impl true
  def opts_def do
    [cd_path: [type: :string, required: true, doc: "Directory to cd into"]]
  end

  @impl true
  def perform(args), do: {:ok, Keyword.fetch!(args, :cd_path)}

  @impl true
  def confirm(_result, args) do
    {:ok, cd: Keyword.fetch!(args, :cd_path)}
  end
end
