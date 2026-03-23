defmodule ProGen.Validate.FilesysTest do
  use ExUnit.Case, async: true

  # We run tests from the project root, so mix.exs, lib/, and .git exist.

  describe "atom checks" do
    test ":has_mix passes when mix.exs exists" do
      assert :ok = ProGen.Validations.run("filesys", checks: [:has_mix])
    end

    test ":no_mix fails when mix.exs exists" do
      assert {:error, msg} = ProGen.Validations.run("filesys", checks: [:no_mix])
      assert msg =~ "File 'mix.exs' already exists"
    end

    test ":has_git passes when .git exists" do
      assert :ok = ProGen.Validations.run("filesys", checks: [:has_git])
    end

    test ":no_git fails when .git exists" do
      assert {:error, msg} = ProGen.Validations.run("filesys", checks: [:no_git])
      assert msg =~ "Directory '.git' already exists"
    end
  end

  describe "tuple checks — file" do
    test "{:has_file, path} passes for existing file" do
      assert :ok = ProGen.Validations.run("filesys", checks: [{:has_file, "mix.exs"}])
    end

    test "{:has_file, path} fails for missing file" do
      assert {:error, msg} =
               ProGen.Validations.run("filesys", checks: [{:has_file, "nonexistent.txt"}])

      assert msg =~ "File 'nonexistent.txt' not found"
    end

    test "{:no_file, path} passes for missing file" do
      assert :ok = ProGen.Validations.run("filesys", checks: [{:no_file, "nonexistent.txt"}])
    end

    test "{:no_file, path} fails for existing file" do
      assert {:error, msg} =
               ProGen.Validations.run("filesys", checks: [{:no_file, "mix.exs"}])

      assert msg =~ "File 'mix.exs' already exists"
    end
  end

  describe "tuple checks — directory" do
    test "{:has_dir, path} passes for existing directory" do
      assert :ok = ProGen.Validations.run("filesys", checks: [{:has_dir, "lib"}])
    end

    test "{:has_dir, path} fails for missing directory" do
      assert {:error, msg} =
               ProGen.Validations.run("filesys", checks: [{:has_dir, "no_such_dir"}])

      assert msg =~ "Directory 'no_such_dir' not found"
    end

    test "{:no_dir, path} passes for missing directory" do
      assert :ok = ProGen.Validations.run("filesys", checks: [{:no_dir, "no_such_dir"}])
    end

    test "{:no_dir, path} fails for existing directory" do
      assert {:error, msg} =
               ProGen.Validations.run("filesys", checks: [{:no_dir, "lib"}])

      assert msg =~ "Directory 'lib' already exists"
    end
  end

  describe "fail-fast behavior" do
    test "stops at first failure and returns its error" do
      assert {:error, msg} =
               ProGen.Validations.run("filesys", checks: [:no_mix, :has_mix])

      assert msg =~ "File 'mix.exs' already exists"
    end

    test "runs all checks when all pass" do
      assert :ok =
               ProGen.Validations.run("filesys",
                 checks: [:has_mix, :has_git, {:has_file, "mix.exs"}, {:has_dir, "lib"}]
               )
    end
  end

  describe "unrecognized term" do
    test "returns error with guidance message" do
      assert {:error, msg} =
               ProGen.Validations.run("filesys", checks: [:bogus])

      assert msg =~ "Unknown term"
      assert msg =~ ":bogus"
    end
  end

  describe "checks/0 introspection" do
    test "returns a non-empty list of {term, desc} tuples" do
      checks = ProGen.Validate.Filesys.checks()
      assert is_list(checks)
      assert length(checks) == 10

      Enum.each(checks, fn entry ->
        assert {term, desc} = entry
        assert is_binary(term)
        assert is_binary(desc)
      end)
    end

    test "contains all 8 filesystem check terms" do
      terms = Enum.map(ProGen.Validate.Filesys.checks(), &elem(&1, 0))

      assert ":has_mix" in terms
      assert ":no_mix" in terms
      assert ":has_git" in terms
      assert ":no_git" in terms
      assert "{:has_file, \"file\"}" in terms
      assert "{:no_file, \"file\"}" in terms
      assert "{:has_dir, \"dir\"}" in terms
      assert "{:no_dir, \"dir\"}" in terms
    end
  end

  describe "module metadata" do
    test "name/0 returns \"filesys\"" do
      assert ProGen.Validate.Filesys.name() == "filesys"
    end

    test "description/0 returns a non-empty string" do
      desc = ProGen.Validate.Filesys.description()
      assert is_binary(desc)
      assert desc != ""
    end

    test "opts_def/0 includes :checks" do
      schema = ProGen.Validate.Filesys.opts_def()
      assert is_list(schema)
      assert Keyword.has_key?(schema, :checks)
    end

    test "is auto-discovered by the registry" do
      validations = ProGen.Validations.list_validations()
      assert Enum.any?(validations, fn {name, _desc} -> name == "filesys" end)
    end
  end
end
