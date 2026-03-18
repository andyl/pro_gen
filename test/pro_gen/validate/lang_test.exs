defmodule ProGen.Validate.LangTest do
  use ExUnit.Case, async: true

  # Tests run in an environment where elixir and erlang are installed.

  describe "elixir checks" do
    test ":has_elixir passes when elixir is installed" do
      assert :ok = ProGen.Validate.Lang.check(:has_elixir)
    end

    test ":no_elixir fails when elixir is installed" do
      assert {:error, msg} = ProGen.Validate.Lang.check(:no_elixir)
      assert msg =~ "elixir is installed"
    end
  end

  describe "erlang checks" do
    test ":has_erlang passes when erlang is installed" do
      assert :ok = ProGen.Validate.Lang.check(:has_erlang)
    end

    test ":no_erlang fails when erlang is installed" do
      assert {:error, msg} = ProGen.Validate.Lang.check(:no_erlang)
      assert msg =~ "erlang is not installed"
    end
  end

  describe "via registry" do
    test "runs elixir check through registry" do
      assert :ok = ProGen.Validations.run("lang", checks: [:has_elixir])
    end

    test "fails on unknown check term" do
      assert {:error, msg} = ProGen.Validations.run("lang", checks: [:bogus])
      assert msg =~ "Unknown term"
    end
  end

  describe "checks/0 introspection" do
    test "returns a non-empty list of {term, desc} tuples" do
      checks = ProGen.Validate.Lang.checks()
      assert is_list(checks)
      assert length(checks) == 6

      Enum.each(checks, fn entry ->
        assert {term, desc} = entry
        assert is_binary(term)
        assert is_binary(desc)
      end)
    end

    test "contains all 6 language check terms" do
      terms = Enum.map(ProGen.Validate.Lang.checks(), &elem(&1, 0))

      assert ":has_elixir" in terms
      assert ":no_elixir" in terms
      assert ":has_ruby" in terms
      assert ":no_ruby" in terms
      assert ":has_erlang" in terms
      assert ":no_erlang" in terms
    end
  end

  describe "module metadata" do
    test "name/0 returns \"lang\"" do
      assert ProGen.Validate.Lang.name() == "lang"
    end

    test "description/0 returns a non-empty string" do
      desc = ProGen.Validate.Lang.description()
      assert is_binary(desc)
      assert desc != ""
    end

    test "option_schema/0 includes :checks" do
      schema = ProGen.Validate.Lang.option_schema()
      assert is_list(schema)
      assert Keyword.has_key?(schema, :checks)
    end

    test "is auto-discovered by the registry" do
      validations = ProGen.Validations.list_validations()
      assert Enum.any?(validations, fn {name, _desc} -> name == "lang" end)
    end
  end
end
