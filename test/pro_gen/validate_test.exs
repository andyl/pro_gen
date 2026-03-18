defmodule ProGen.ValidateTest do
  use ExUnit.Case

  describe "ProGen.Validate attribute accessors" do
    test "name/0 returns the derived string name" do
      assert ProGen.Validate.Filesys.name() == "filesys"
    end

    test "description/0 returns the declared description" do
      desc = ProGen.Validate.Filesys.description()
      assert is_binary(desc)
      assert desc != ""
    end

    test "option_schema/0 includes :checks" do
      schema = ProGen.Validate.Filesys.option_schema()
      assert is_list(schema)
      assert Keyword.has_key?(schema, :checks)
    end
  end

  describe "missing @moduledoc" do
    test "raises CompileError" do
      assert_raise CompileError, ~r/must set @moduledoc/, fn ->
        Code.compile_string("""
        defmodule ProGen.Validate.NoDoc do
          @moduledoc false
          use ProGen.Validate
        end
        """)
      end
    end
  end

  describe "name derivation" do
    test "nested module segments are dot-joined" do
      Code.compile_string("""
      defmodule ProGen.Validate.Test.Nested do
        @moduledoc "Nested test validator"
        use ProGen.Validate
      end
      """)

      assert apply(ProGen.Validate.Test.Nested, :name, []) == "test.nested"
    end
  end
end
