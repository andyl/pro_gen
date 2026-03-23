defmodule ProGen.CodeMods.DepsTweaks do

  @moduledoc "Tweaks to dependency specs in mix.exs"

  # set_only instructions:
  # - this function updates the --only clause on a depdency in the mix file
  # - I don't really love the name 'set_only' - see if you can suggest a better name
  # - use sourceror, igniter or regex to make the changes - whatever you think is most reliable
  # - raise an error if the file 'mix.exs' is not found

  def set_only(dependency) do
    # removes the --only argument from a dependency in the mix file
    # examples:
    # set_only(:usage_rules)
    # - input {:usage_rules, "~> 0.2", only: [:dev, :test]}
    # - output {:usage_rules, "~> 0.2"}
    #
    # - input {:usage_rules, "~> 0.2"}
    # - output {:usage_rules, "~> 0.2"}
  end

  def set_only(dependency, spec) do
    # removes the --only argument from a dependency in the mix file
    # examples:
    # set_only(:usage_rules, [:dev, :test])
    # - input {:usage_rules, "~> 0.2"}
    # - output {:usage_rules, "~> 0.2", only: [:dev, :test]}
    #
    # - input {:usage_rules, "~> 0.2", only: :dev}
    # - output {:usage_rules, "~> 0.2", only: [:dev, :test]}
  end
end
