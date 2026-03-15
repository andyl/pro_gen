defmodule ProGen.Action.ValidateTest do
  use ExUnit.Case

  # We run tests from the project root, so mix.exs, lib/, and .git exist.

  describe "atom checks" do
    test ":has_mix passes when mix.exs exists" do
      assert :ok = ProGen.Actions.run("validate", checks: [:has_mix])
    end

    test ":no_mix fails when mix.exs exists" do
      assert {:error, msg} = ProGen.Actions.run("validate", checks: [:no_mix])
      assert msg =~ "File 'mix.exs' already exists"
    end

    test ":has_git passes when .git exists" do
      assert :ok = ProGen.Actions.run("validate", checks: [:has_git])
    end

    test ":no_git fails when .git exists" do
      assert {:error, msg} = ProGen.Actions.run("validate", checks: [:no_git])
      assert msg =~ "Directory '.git' already exists"
    end
  end

  describe "tuple checks — file" do
    test "{:has_file, path} passes for existing file" do
      assert :ok = ProGen.Actions.run("validate", checks: [{:has_file, "mix.exs"}])
    end

    test "{:has_file, path} fails for missing file" do
      assert {:error, msg} =
               ProGen.Actions.run("validate", checks: [{:has_file, "nonexistent.txt"}])

      assert msg =~ "File 'nonexistent.txt' not found"
    end

    test "{:no_file, path} passes for missing file" do
      assert :ok = ProGen.Actions.run("validate", checks: [{:no_file, "nonexistent.txt"}])
    end

    test "{:no_file, path} fails for existing file" do
      assert {:error, msg} =
               ProGen.Actions.run("validate", checks: [{:no_file, "mix.exs"}])

      assert msg =~ "File 'mix.exs' already exists"
    end
  end

  describe "tuple checks — directory" do
    test "{:has_dir, path} passes for existing directory" do
      assert :ok = ProGen.Actions.run("validate", checks: [{:has_dir, "lib"}])
    end

    test "{:has_dir, path} fails for missing directory" do
      assert {:error, msg} =
               ProGen.Actions.run("validate", checks: [{:has_dir, "no_such_dir"}])

      assert msg =~ "Directory 'no_such_dir' not found"
    end

    test "{:no_dir, path} passes for missing directory" do
      assert :ok = ProGen.Actions.run("validate", checks: [{:no_dir, "no_such_dir"}])
    end

    test "{:no_dir, path} fails for existing directory" do
      assert {:error, msg} =
               ProGen.Actions.run("validate", checks: [{:no_dir, "lib"}])

      assert msg =~ "Directory 'lib' already exists"
    end
  end

  describe "elixir checks" do
    test ":has_elixir passes when elixir is installed" do
      assert :ok = ProGen.Action.Validate.check(:has_elixir)
    end

    test ":no_elixir fails when elixir is installed" do
      assert {:error, msg} = ProGen.Action.Validate.check(:no_elixir)
      assert msg =~ "elixir is installed"
    end
  end

  describe "igniter checks" do
    test ":has_igniter passes when igniter is available" do
      assert :ok = ProGen.Action.Validate.check(:has_igniter)
    end

    test ":no_igniter fails when igniter is available" do
      assert {:error, msg} = ProGen.Action.Validate.check(:no_igniter)
      assert msg =~ "Igniter is installed"
    end
  end

  describe "phx_new checks" do
    test ":has_phx_new and :no_phx_new are mutually exclusive" do
      has_result = ProGen.Action.Validate.check(:has_phx_new)
      no_result = ProGen.Action.Validate.check(:no_phx_new)
      assert has_result == :ok != (no_result == :ok)
    end
  end

  describe "fail-fast behavior" do
    test "stops at first failure and returns its error" do
      assert {:error, msg} =
               ProGen.Actions.run("validate", checks: [:no_mix, :has_mix])

      assert msg =~ "File 'mix.exs' already exists"
    end

    test "runs all checks when all pass" do
      assert :ok =
               ProGen.Actions.run("validate",
                 checks: [:has_mix, :has_git, {:has_file, "mix.exs"}, {:has_dir, "lib"}]
               )
    end
  end

  describe "unrecognized term" do
    test "returns error with guidance message" do
      assert {:error, msg} =
               ProGen.Actions.run("validate", checks: [:bogus])

      assert msg =~ "Unrecognized term"
      assert msg =~ ":bogus"
      assert msg =~ "ProGen.Action.Validate.checks/0"
    end
  end

  describe "missing :checks option" do
    test "returns validation error" do
      assert {:error, msg} = ProGen.Actions.run("validate", [])
      assert is_binary(msg)
      assert msg =~ "checks"
    end
  end

  describe "checks/0 introspection" do
    test "returns a non-empty list of maps with :term and :desc" do
      checks = ProGen.Action.Validate.checks()
      assert is_list(checks)
      assert length(checks) > 0

      Enum.each(checks, fn entry ->
        assert Map.has_key?(entry, :term)
        assert Map.has_key?(entry, :desc)
        refute Map.has_key?(entry, :test)
      end)
    end

    test "contains all 14 built-in check terms" do
      terms = Enum.map(ProGen.Action.Validate.checks(), & &1.term)

      assert :no_mix in terms
      assert :has_mix in terms
      assert :no_git in terms
      assert :has_git in terms
      assert {:no_file, "file"} in terms
      assert {:has_file, "file"} in terms
      assert {:no_dir, "dir"} in terms
      assert {:has_dir, "dir"} in terms
      assert :has_igniter in terms
      assert :no_igniter in terms
      assert :has_phx_new in terms
      assert :no_phx_new in terms
      assert :has_elixir in terms
      assert :no_elixir in terms
    end
  end

  describe "module metadata" do
    test "name/0 returns \"validate\"" do
      assert ProGen.Action.Validate.name() == "validate"
    end

    test "description/0 returns a non-empty string" do
      desc = ProGen.Action.Validate.description()
      assert is_binary(desc)
      assert desc != ""
    end

    test "option_schema/0 includes :checks" do
      schema = ProGen.Action.Validate.option_schema()
      assert is_list(schema)
      assert Keyword.has_key?(schema, :checks)
    end

    test "is auto-discovered by the registry" do
      assert "validate" in ProGen.Actions.list_actions()
    end
  end
end
