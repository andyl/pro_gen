defmodule ProGen.ActionTest do
  use ExUnit.Case

  describe "ProGen.Action attribute accessors" do
    test "name/0 returns the derived atom name" do
      assert ProGen.Action.Run.name() == :run
    end

    test "description/0 returns the declared description" do
      assert ProGen.Action.Run.description() == "Run a system command"
    end

    test "option_schema/0 returns the declared schema" do
      schema = ProGen.Action.Run.option_schema()
      assert is_list(schema)
      assert Keyword.has_key?(schema, :command)
      assert Keyword.has_key?(schema, :args)
      assert Keyword.has_key?(schema, :dir)
    end

    test "missing @description raises CompileError" do
      assert_raise CompileError, ~r/must set @description/, fn ->
        Code.compile_string("""
        defmodule ProGen.Action.NoDesc do
          use ProGen.Action

          @impl true
          def perform(_args), do: :ok
        end
        """)
      end
    end
  end
end
