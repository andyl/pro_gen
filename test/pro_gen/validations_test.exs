defmodule ProGen.ValidationsTest do
  use ExUnit.Case

  describe "list_validations/0" do
    test "includes all four validators" do
      validations = ProGen.Validations.list_validations()
      names = Enum.map(validations, &elem(&1, 0))

      assert "filesys" in names
      assert "gem" in names
      assert "hex" in names
      assert "lang" in names
    end
  end

  describe "validation_module/1" do
    test "returns the correct module for 'filesys'" do
      assert {:ok, ProGen.Validate.Filesys} = ProGen.Validations.validation_module("filesys")
    end

    test "returns the correct module for 'gem'" do
      assert {:ok, ProGen.Validate.Gem} = ProGen.Validations.validation_module("gem")
    end

    test "returns :error for unknown validator" do
      assert :error = ProGen.Validations.validation_module("nonexistent")
    end
  end

  describe "validation_info/1" do
    test "returns metadata map for 'filesys'" do
      assert {:ok, info} = ProGen.Validations.validation_info("filesys")
      assert info.module == ProGen.Validate.Filesys
      assert info.name == "filesys"
      assert is_binary(info.description)
      assert is_list(info.checks)
      assert length(info.checks) == 8
    end

    test "returns metadata map for 'gem'" do
      assert {:ok, info} = ProGen.Validations.validation_info("gem")
      assert info.module == ProGen.Validate.Gem
      assert info.name == "gem"
      assert is_list(info.checks)
      assert length(info.checks) == 12
    end

    test "returns error for unknown validator" do
      assert {:error, msg} = ProGen.Validations.validation_info("nonexistent")
      assert msg =~ "Unknown validator"
    end
  end

  describe "run/2" do
    test "executes checks and returns :ok" do
      assert :ok = ProGen.Validations.run("filesys", checks: [:has_mix])
    end

    test "returns error on failed check" do
      assert {:error, msg} = ProGen.Validations.run("filesys", checks: [:no_mix])
      assert msg =~ "mix.exs"
    end

    test "returns error for unknown validator" do
      assert {:error, msg} = ProGen.Validations.run("nonexistent", checks: [:has_mix])
      assert msg =~ "Unknown validator"
    end

    test "returns validation error for missing :checks option" do
      assert {:error, msg} = ProGen.Validations.run("filesys", [])
      assert is_binary(msg)
      assert msg =~ "checks"
    end
  end

  describe "run/2 with module" do
    test "executes checks and returns :ok with a valid module" do
      assert :ok = ProGen.Validations.run(ProGen.Validate.Filesys, checks: [:has_mix])
    end

    test "returns error on failed check with a valid module" do
      assert {:error, msg} = ProGen.Validations.run(ProGen.Validate.Filesys, checks: [:no_mix])
      assert msg =~ "mix.exs"
    end

    test "returns error for non-existent module" do
      assert {:error, msg} =
               ProGen.Validations.run(ProGen.Validate.DoesNotExist, checks: [:has_mix])
      assert msg =~ "does not exist or could not be loaded"
    end

    test "returns error for non-validator module" do
      assert {:error, msg} = ProGen.Validations.run(String, checks: [:has_mix])
      assert msg =~ "is not a ProGen.Validate validator"
    end
  end
end
