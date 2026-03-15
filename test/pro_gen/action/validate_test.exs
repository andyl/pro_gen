defmodule ProGen.Action.ValidateTest do
  use ExUnit.Case

  # We run tests from the project root, so mix.exs, lib/, and .git exist.

  describe "atom checks" do
    test ":has_mix passes when mix.exs exists" do
      assert {:ok, :ok} = ProGen.Actions.run(:validate, checks: [:has_mix])
    end

    test ":no_mix fails when mix.exs exists" do
      assert {:ok, {:error, msg}} = ProGen.Actions.run(:validate, checks: [:no_mix])
      assert msg =~ "mix.exs already exists"
    end

    test ":has_git passes when .git exists" do
      assert {:ok, :ok} = ProGen.Actions.run(:validate, checks: [:has_git])
    end

    test ":no_git fails when .git exists" do
      assert {:ok, {:error, msg}} = ProGen.Actions.run(:validate, checks: [:no_git])
      assert msg =~ ".git already exists"
    end
  end

  describe "tuple checks — file" do
    test "{:has_file, path} passes for existing file" do
      assert {:ok, :ok} = ProGen.Actions.run(:validate, checks: [{:has_file, "mix.exs"}])
    end

    test "{:has_file, path} fails for missing file" do
      assert {:ok, {:error, msg}} =
               ProGen.Actions.run(:validate, checks: [{:has_file, "nonexistent.txt"}])

      assert msg =~ "nonexistent.txt not found"
    end

    test "{:no_file, path} passes for missing file" do
      assert {:ok, :ok} = ProGen.Actions.run(:validate, checks: [{:no_file, "nonexistent.txt"}])
    end

    test "{:no_file, path} fails for existing file" do
      assert {:ok, {:error, msg}} =
               ProGen.Actions.run(:validate, checks: [{:no_file, "mix.exs"}])

      assert msg =~ "mix.exs already exists"
    end
  end

  describe "tuple checks — directory" do
    test "{:has_dir, path} passes for existing directory" do
      assert {:ok, :ok} = ProGen.Actions.run(:validate, checks: [{:has_dir, "lib"}])
    end

    test "{:has_dir, path} fails for missing directory" do
      assert {:ok, {:error, msg}} =
               ProGen.Actions.run(:validate, checks: [{:has_dir, "no_such_dir"}])

      assert msg =~ "no_such_dir not found"
    end

    test "{:no_dir, path} passes for missing directory" do
      assert {:ok, :ok} = ProGen.Actions.run(:validate, checks: [{:no_dir, "no_such_dir"}])
    end

    test "{:no_dir, path} fails for existing directory" do
      assert {:ok, {:error, msg}} =
               ProGen.Actions.run(:validate, checks: [{:no_dir, "lib"}])

      assert msg =~ "lib already exists"
    end

    test "{:dir_free, path} passes for empty directory" do
      tmp =
        Path.join(System.tmp_dir!(), "validate_test_empty_#{System.unique_integer([:positive])}")

      File.mkdir_p!(tmp)

      try do
        assert {:ok, :ok} = ProGen.Actions.run(:validate, checks: [{:dir_free, tmp}])
      after
        File.rm_rf!(tmp)
      end
    end

    test "{:dir_free, path} fails for non-empty directory" do
      assert {:ok, {:error, msg}} = ProGen.Actions.run(:validate, checks: [{:dir_free, "lib"}])
      assert msg =~ "lib is not empty"
    end

    test "{:dir_free, path} fails for non-existent path" do
      assert {:ok, {:error, msg}} =
               ProGen.Actions.run(:validate, checks: [{:dir_free, "no_such_dir"}])

      assert msg =~ "no_such_dir is not a directory"
    end
  end

  describe "fail-fast behavior" do
    test "stops at first failure and returns its error" do
      assert {:ok, {:error, msg}} =
               ProGen.Actions.run(:validate, checks: [:no_mix, :has_mix])

      assert msg =~ "mix.exs already exists"
    end

    test "runs all checks when all pass" do
      assert {:ok, :ok} =
               ProGen.Actions.run(:validate,
                 checks: [:has_mix, :has_git, {:has_file, "mix.exs"}, {:has_dir, "lib"}]
               )
    end
  end

  describe "unrecognized term" do
    test "returns error with guidance message" do
      assert {:ok, {:error, msg}} =
               ProGen.Actions.run(:validate, checks: [:bogus])

      assert msg =~ "Unrecognized term"
      assert msg =~ ":bogus"
      assert msg =~ "ProGen.Action.Validate.checks/0"
    end
  end

  describe "missing :checks option" do
    test "returns validation error" do
      assert {:error, msg} = ProGen.Actions.run(:validate, [])
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
        refute Map.has_key?(entry, :func)
      end)
    end

    test "contains all 9 built-in check terms" do
      terms = Enum.map(ProGen.Action.Validate.checks(), & &1.term)

      assert :no_mix in terms
      assert :has_mix in terms
      assert :no_git in terms
      assert :has_git in terms
      assert {:no_file, "path"} in terms
      assert {:has_file, "path"} in terms
      assert {:no_dir, "path"} in terms
      assert {:has_dir, "path"} in terms
      assert {:dir_free, "path"} in terms
    end
  end

  describe "module metadata" do
    test "name/0 returns :validate" do
      assert ProGen.Action.Validate.name() == :validate
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
      assert :validate in ProGen.Actions.list_actions()
    end
  end
end
