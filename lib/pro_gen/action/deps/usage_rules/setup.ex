defmodule ProGen.Action.Deps.UsageRules.Setup do
  @moduledoc """
  Setup UsageRules

  Skips installation when the archive is already present.
  Pass `force: true` to reinstall regardless.
  """

  use ProGen.Action

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
    IO.puts("HELLO WORLD")
    ProGen.Sys.cmd("pwd")
    ProGen.Sys.cmd("ls -al")
    IO.puts("ONE")
    MixFile.add_to_project(:usage_rules, "usage_rules()") |> IO.inspect(label: "VONE")
    IO.puts("TWO")
    MixFile.add_defp(:usage_rules, 0, body())             |> IO.inspect(label: "VTWO")
    IO.puts("THREE")
    # usage_rules.sync mix task depends on Igniter at runtime;
    # igniter.install rejects installing itself, so use igniter.setup
    ProGen.Sys.cmd("cat mix.exs")                         |> IO.inspect(label: "VSYNC")
    # ProGen.Sys.cmd("mix igniter.setup --yes")
    IO.puts("FOUR")
    ProGen.Sys.cmd("mix usage_rules.sync")                |> IO.inspect(label: "VSYNC")
    IO.puts("FIVE")
    :ok
  end

  @impl true
  def confirm(_result, _args) do
    if File.exists?("RULES.md"), do: :ok, else: {:error, "RULES.md was not created"}
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

