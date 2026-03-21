defmodule ProGen.Action.Deps.UsageRules.Setup do
  @moduledoc """
  Setup UsageRules

  Skips installation when the archive is already present.
  Pass `force: true` to reinstall regardless.
  """

  use ProGen.Action

  @validate [{"filesys", [{:has_file, "mix.exs"}]}]

  @impl true
  def depends_on(_args) do
    [{"deps.install", [dep: "usage_rules"]}]
  end

  @impl true
  def needed?(_args) do
    not File.exists?("RULES.md")
  end

  @impl true
  def perform(_args) do
    # these are idempotent...
    ProGen.CodeMods.MixFile.add_to_project(:usage_rules, "usage_rules()")
    ProGen.CodeMods.MixFile.add_defp(:usage_rules, 0, body())
    # always regenerate to sync changes
    ProGen.Sys.cmd("mix usage_rules.sync --yes")
    :ok
  end

  @impl true
  def confirm(_result, _args) do
    if File.exists?("RULES.md") do
      :ok
    else
      {:error, "RULES.md was not created"}
    end
  end

  # -----

  def body do
    """
    defp usage_rules do
      [
        file: "RULES.md",
        usage_rules: [{~r/.*/, link: :markdown}],
      ]
    end
    """
  end
end

