defmodule ProGen.Validate.Lang do
  @moduledoc """
  Validation checks for common languages (elixir, erlang, python, etc.)

  Use `checks/0` to discover available checks at runtime.
  """

  use ProGen.Validate

  defcheck :has_elixir do
    desc "Pass if Elixir is installed"
    fail "No Elixir - please install"
    test fn _ -> System.find_executable("elixir") != nil end
  end

  defcheck :no_elixir do
    desc "Pass if elixir is not installed"
    fail "elixir is installed"
    test fn _ -> not eval_test(:has_elixir) end
  end

  defcheck :has_ruby do
    desc "Pass if ruby is installed"
    fail "No Ruby - please install"
    test fn _ -> System.find_executable("ruby") != nil end
  end

  defcheck :no_ruby do
    desc "Pass if ruby is installed"
    fail "Ruby is not installed"
    test fn _ -> not eval_test(:has_ruby) end
  end

  defcheck :has_erlang do
    desc "Pass if erlang is installed"
    fail "No erlang - please install"
    test fn _ -> System.find_executable("erl") != nil end
  end

  defcheck :no_erlang do
    desc "Pass if erlang is installed"
    fail "erlang is not installed"
    test fn _ -> not eval_test(:has_erlang) end
  end

end
