defmodule ProGen.Validate.Hex do
  @moduledoc """
  Validation checks for hex packages.

  Use `checks/0` to discover available checks at runtime.
  """

  use ProGen.Validate

  defcheck :has_igniter_new do
    desc "Pass if igniter_new is installed"
    fail "No igniter_new (install with 'mix archive.install hex igniter_new --force')"
    test fn _ -> elem(System.cmd("mix", ["help"]), 0) =~ "igniter" end
  end

  defcheck :no_igniter do
    desc "Pass if igniter is not installed"
    fail "Igniter is installed"
    test fn _ -> not eval_test(:has_igniter) end
  end

  defcheck :has_phx_new do
    desc "Pass if phx_new is installed"
    fail "No phx_new (install with 'mix archive.install hex phx_new_new --force')"
    test fn _ -> elem(System.cmd("mix", ["help"]), 0) =~ "phx.new" end
  end

  defcheck :no_phx_new do
    desc "Pass if phx_new is not installed"
    fail "phx_new is installed"
    test fn _ -> not eval_test(:has_phx_new) end
  end

  defcheck :has_tableau_new do
    desc "Pass if tableau_new is installed"
    fail "No tableau_new (install with 'mix archive.install hex tableau_new_new --force')"
    test fn _ -> elem(System.cmd("mix", ["help"]), 0) =~ "tableau.new" end
  end

  defcheck :no_tableau_new do
    desc "Pass if tableau_new is not installed"
    fail "tableau_new is installed"
    test fn _ -> not eval_test(:has_tableau_new) end
  end
end
