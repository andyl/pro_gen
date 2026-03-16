defmodule ProGen.ValidationsTest do
  use ExUnit.Case

  describe "list_validations/0" do
    test "includes 'basics'" do
      assert {"basics", "Basic filesystem and tool checks"} in ProGen.Validations.list_validations()
    end
  end

  describe "validation_module/1" do
    test "returns the correct module for 'basics'" do
      assert {:ok, ProGen.Validate.Basics} = ProGen.Validations.validation_module("basics")
    end

    test "returns :error for unknown validator" do
      assert :error = ProGen.Validations.validation_module("nonexistent")
    end
  end

  describe "validation_info/1" do
    test "returns metadata map for 'basics'" do
      assert {:ok, info} = ProGen.Validations.validation_info("basics")
      assert info.module == ProGen.Validate.Basics
      assert info.name == "basics"
      assert info.description == "Basic filesystem and tool checks"
      assert is_list(info.checks)
      assert length(info.checks) > 0
    end

    test "returns error for unknown validator" do
      assert {:error, msg} = ProGen.Validations.validation_info("nonexistent")
      assert msg =~ "Unknown validator"
    end
  end

  describe "run/2" do
    test "executes checks and returns :ok" do
      assert :ok = ProGen.Validations.run("basics", checks: [:has_mix])
    end

    test "returns error on failed check" do
      assert {:error, msg} = ProGen.Validations.run("basics", checks: [:no_mix])
      assert msg =~ "mix.exs"
    end

    test "returns error for unknown validator" do
      assert {:error, msg} = ProGen.Validations.run("nonexistent", checks: [:has_mix])
      assert msg =~ "Unknown validator"
    end

    test "returns validation error for missing :checks option" do
      assert {:error, msg} = ProGen.Validations.run("basics", [])
      assert is_binary(msg)
      assert msg =~ "checks"
    end
  end

  describe "run/2 with module" do
    test "executes checks and returns :ok with a valid module" do
      assert :ok = ProGen.Validations.run(ProGen.Validate.Basics, checks: [:has_mix])
    end

    test "returns error on failed check with a valid module" do
      assert {:error, msg} = ProGen.Validations.run(ProGen.Validate.Basics, checks: [:no_mix])
      assert msg =~ "mix.exs"
    end

    test "returns error for non-existent module" do
      assert {:error, msg} = ProGen.Validations.run(ProGen.Validate.DoesNotExist, checks: [:has_mix])
      assert msg =~ "does not exist or could not be loaded"
    end

    test "returns error for non-validator module" do
      assert {:error, msg} = ProGen.Validations.run(String, checks: [:has_mix])
      assert msg =~ "is not a ProGen.Validate validator"
    end
  end

  describe "duplicate detection" do
    test "raises ArgumentError for duplicate validator names" do
      Code.compile_string("""
      defmodule ProGen.Validate.Dup do
        use ProGen.Validate
        @description "First"
      end
      """)

      Code.compile_string("""
      defmodule ProGen.FakeValidateNs.Dup do
        use ProGen.Validate
        @description "Second"
      end
      """)

      assert_raise ArgumentError, ~r/Duplicate validator name detected: "dup"/, fn ->
        ProGen.Validations.build_validation_map([
          ProGen.Validate.Dup,
          ProGen.FakeValidateNs.Dup
        ])
      end
    end
  end
end
