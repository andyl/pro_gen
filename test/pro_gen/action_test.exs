defmodule ProGen.ActionTest do
  use ExUnit.Case

  describe "ProGen.Action callbacks" do
    test "name/0 returns the derived string name" do
      assert ProGen.Action.IO.Echo.name() == "io.echo"
    end

    test "description/0 returns first line of @moduledoc" do
      assert ProGen.Action.IO.Echo.description() == "Echo a message to stdout."
    end

    test "opts_def/0 returns the declared schema" do
      schema = ProGen.Action.IO.Echo.opts_def()
      assert is_list(schema)
      assert Keyword.has_key?(schema, :message)
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

    test "missing @moduledoc raises CompileError" do
      assert_raise CompileError, ~r/must set @moduledoc/, fn ->
        Code.compile_string("""
        defmodule ProGen.Action.NoDesc do
          @moduledoc false
          use ProGen.Action

          @impl true
          def perform(_args), do: :ok
        end
        """)
      end
    end
  end

  describe "validate/1 callback" do
    test "returns [] by default (no validate/1 override)" do
      assert ProGen.Action.IO.Echo.validate([]) == []
    end

    test "returns declared list when validate/1 is overridden" do
      assert ProGen.Action.Test.ValidatePass.validate([]) == [{"filesys", [:has_mix]}]
    end

    test "returns declared list for failing fixture" do
      assert ProGen.Action.Test.ValidateFail.validate([]) == [{"filesys", [:no_mix]}]
    end
  end

  describe "confirm/2 callback" do
    test "default confirm/2 returns :ok" do
      assert ProGen.Action.IO.Echo.confirm(:ok, []) == :ok
    end

    test "confirm/2 can be overridden" do
      assert ProGen.Action.Test.ConfirmFail.confirm(:ok, []) == {:error, "boom"}
    end
  end

  describe "needed?/1 predicate" do
    test "default needed?/1 returns true" do
      assert ProGen.Action.IO.Echo.needed?([]) == true
    end

    test "needed?/1 can be overridden" do
      Code.compile_string("""
      defmodule ProGen.Action.Test.OverrideNeeded do
        @moduledoc "Action that overrides needed?/1"
        use ProGen.Action

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
