defmodule ProGen.Action.Deps.UsageRules.Setup do
  @moduledoc """
  Setup UsageRules

  Skips installation when the archive is already present.
  Pass `force: true` to reinstall regardless.
  """

  use ProGen.Action

  alias ProGen.Script, as: PS
  alias ProGen.CodeMods.MixFile

  @validate [{"filesys", [{:has_file, "mix.exs"}]}]

  @impl true
  def depends_on(_args) do
    [{"archive.install", [package: "usage_rules"]}]
  end

  @impl true
  def needed?(_args) do
    not File.exists?("RULES.md")
  end

  @impl true
  def perform(_args) do
    MixFile.add_to_project(:usage_rules, "usage_rules()")
    MixFile.add_defp(:usage_rules, 0, body())
    PS.puts("the command 'mix usage_rules.sync' is broken!")
    PS.puts("see https://github.com/ash-project/usage_rules/issues/62")
    PS.puts("try running manually...")
    :ok
  end

  @impl true
  def confirm(_result, _args) do
    # if File.exists?("RULES.md"), do: :ok, else: {:error, "RULES.md was not created"}
    true
  end

  # -----

  defp body do
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

