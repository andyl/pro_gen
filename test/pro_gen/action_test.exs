defmodule ProGen.ActionTest do
  use ExUnit.Case

  describe "ProGen.Action attribute accessors" do
    test "name/0 returns the derived string name" do
      assert ProGen.Action.Run.name() == "run"
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

    test "name/0 returns a dot-joined namespace for nested modules" do
      assert ProGen.Action.Test.Echo2.name() == "test.echo2"
    end

    test "namespaced action is discoverable by its full name" do
      assert {:ok, ProGen.Action.Test.Echo2} = ProGen.Actions.action_module("test.echo2")
    end

    test "namespaced action can be run by its full name" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          assert :ok = ProGen.Actions.run("test.echo2", message: "hi")
        end)

      assert output =~ "hi"
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

  describe "needed?/1 predicate" do
    test "default needed?/1 returns true" do
      assert ProGen.Action.Run.needed?([]) == true
    end

    test "needed?/1 can be overridden" do
      Code.compile_string("""
      defmodule ProGen.Action.Test.OverrideNeeded do
        use ProGen.Action

        @description "Action that overrides needed?/1"
        @option_schema []

        @impl true
        def needed?(_args), do: false

        @impl true
        def perform(_args), do: :ok
      end
      """)

      assert apply(ProGen.Action.Test.OverrideNeeded, :needed?, [[]]) == false
    end
  end
end
