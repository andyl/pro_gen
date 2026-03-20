defmodule ProGen.Validate.Mix do
  @moduledoc """
  Validation checks for hex packages.

  Use `checks/0` to discover available checks at runtime.
  """

  use ProGen.Validate

  defcheck :has_mixfile do
    desc "Pass if 'mix.exs' exists"
    fail "File 'mix.exs' not found"
    test fn _ -> File.exists?("mix.exs") end
  end

  defcheck :no_mixfile do
    desc "Pass if 'mix.exs' does not exist"
    fail "File 'mix.exs' already exists"
    test fn _ -> not eval_test(:has_mixfile) end
  end

  defcheck {:has_dep, "dep"} do
    desc "Pass if <dep> is installed"
    fail fn {:has_dep, dep} -> "No #{dep} found in mix.exs" end
    test fn {:has_dep, dep} -> elem(System.cmd("mix", ["help"]), 0) =~ dep end
  end

  defcheck {:no_dep, "dep"} do
    desc "Pass if <dep> is not installed"
    fail fn {:has_dep, dep} -> "Dependency #{dep} found in mix.exs" end
    test fn {:has_dep, dep} -> not eval_test({:has_dep, dep}) end
  end

end
