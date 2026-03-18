defmodule ProGen.Validate.HexTest do
  use ExUnit.Case, async: true

  # Skipping runtime checks for has_igniter, no_igniter, has_phx_new, no_phx_new
  # because they shell out to `mix help` which is slow and environment-dependent.

  describe "checks/0 introspection" do
    test "returns a non-empty list of {term, desc} tuples" do
      checks = ProGen.Validate.Hex.checks()
      assert is_list(checks)
      assert length(checks) == 4

      Enum.each(checks, fn entry ->
        assert {term, desc} = entry
        assert is_binary(term)
        assert is_binary(desc)
      end)
    end

    test "contains all 4 hex check terms" do
      terms = Enum.map(ProGen.Validate.Hex.checks(), &elem(&1, 0))

      assert ":has_igniter" in terms
      assert ":no_igniter" in terms
      assert ":has_phx_new" in terms
      assert ":no_phx_new" in terms
    end
  end

  describe "module metadata" do
    test "name/0 returns \"hex\"" do
      assert ProGen.Validate.Hex.name() == "hex"
    end

    test "description/0 returns a non-empty string" do
      desc = ProGen.Validate.Hex.description()
      assert is_binary(desc)
      assert desc != ""
    end

    test "option_schema/0 includes :checks" do
      schema = ProGen.Validate.Hex.option_schema()
      assert is_list(schema)
      assert Keyword.has_key?(schema, :checks)
    end

    test "is auto-discovered by the registry" do
      validations = ProGen.Validations.list_validations()
      assert Enum.any?(validations, fn {name, _desc} -> name == "hex" end)
    end
  end
end
