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

  defcheck :has_dep do
    desc "Pass if igniter_new is installed"
    fail "No igniter_new (install with 'mix archive.install hex igniter_new --force')"
    test fn _ -> elem(System.cmd("mix", ["help"]), 0) =~ "igniter" end
  end

  defcheck :no_dep do
    desc "Pass if igniter is not installed"
    fail "Igniter is installed"
    test fn _ -> not eval_test(:has_igniter) end
  end

end
