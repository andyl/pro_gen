defmodule ProGen.Action.Deps.UsageRules.Setup do
  @moduledoc """
  Setup UsageRules

  Learn more about UsageRules config on the README.

  https://github.com/ash-project/usage_rules/blob/main/README.md

  This Action skips installation when the dependency is already present.
  Pass `force: true` to reinstall regardless.

  Updates the mix file with initial UsageRules configuration. See
  ProGen.Patch.Pkg.UsageRules for the patch code.

  The default configuration ingests all usage_rules for all dependencies
  and creates a file `RULES.md`.

  The project maintainer must perform the following periodic actions:

  1. run `mix usage_rules.sync` as dependencies change
  2. visit the `usage_rules` config in the mix.exs file to update skills
  """

  use ProGen.Action

  @impl true
  def validate(_args), do: [{"filesys", [{:has_file, "mix.exs"}]}]

  @impl true
  def depends_on(_args) do
    [{"deps.install", [deps: "usage_rules", only: "dev,test"]}]
  end

  @impl true
  def needed?(_args) do
    not File.exists?("RULES.md")
  end

  @impl true
  def perform(_args) do
    # these are idempotent...
    ProGen.Patch.Pkg.UsageRules.add_to_project(:usage_rules, "usage_rules()")
    ProGen.Patch.Pkg.UsageRules.add_defp(:usage_rules, 0, body())
    # sync changes
    ProGen.Xt.Sys.cmd("mix usage_rules.sync --yes")
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
    # see https://github.com/ash-project/usage_rules#configuration
    defp usage_rules do
      [
        # link to every `usage_rules.md` found across all dependencies
        usage_rules: [{~r/.*/, link: :markdown}],
        file: "RULES.md",
      ]
    end
    """
  end
end
