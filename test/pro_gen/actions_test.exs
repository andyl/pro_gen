defmodule ProGen.ActionsTest do
  use ExUnit.Case

  describe "ProGen.Actions.run/2" do
    test "validates and performs a valid action" do
      assert {output, 0} =
               ProGen.Actions.run("run", command: "echo", args: ["hello"])

      assert String.trim(output) == "hello"
    end

    test "returns error for missing required args" do
      assert {:error, message} = ProGen.Actions.run("run", [])
      assert is_binary(message)
      assert message =~ "command"
    end

    test "returns error for unknown action" do
      assert {:error, message} = ProGen.Actions.run("nonexistent", [])
      assert message =~ "Unknown action"
    end
  end

  describe "duplicate detection" do
    test "raises ArgumentError when two modules derive to the same action name" do
      # Both modules produce "dup" after Enum.drop(2) — the first two segments differ
      # but the remainder is the same.
      Code.compile_string("""
      defmodule ProGen.Action.Dup do
        use ProGen.Action
        @description "First"
        @impl true
        def perform(_), do: :ok
      end
      """)

      Code.compile_string("""
      defmodule ProGen.FakeNs.Dup do
        use ProGen.Action
        @description "Second"
        @impl true
        def perform(_), do: :ok
      end
      """)

      assert_raise ArgumentError, ~r/Duplicate action name detected: "dup"/, fn ->
        ProGen.Actions.build_action_map([ProGen.Action.Dup, ProGen.FakeNs.Dup])
      end
    end
  end

  describe "needed?/1 integration" do
    test "action skipped when needed?/1 returns false" do
      assert {:ok, :skipped} =
               ProGen.Actions.run("test.never_needed", message: "hello")
    end

    test "force: true bypasses needed?/1 check" do
      assert :ok =
               ProGen.Actions.run("test.never_needed", message: "hello", force: true)
    end

    test ":force does not leak into validated args" do
      ProGen.Actions.run("test.args_capture", message: "hi", force: true)
      captured = Process.get(:captured_args)
      refute Keyword.has_key?(captured, :force)
      assert Keyword.get(captured, :message) == "hi"
    end

    test "validation errors returned even when needed?/1 would return false" do
      assert {:error, message} = ProGen.Actions.run("test.never_needed", [])
      assert message =~ "message"
    end

    test "needed?/1 receives validated args with defaults applied" do
      ProGen.Actions.run("test.default_check", [])
      needed_args = Process.get(:needed_args)
      assert Keyword.get(needed_args, :label) == "default_value"
    end
  end

  describe "ProGen.Actions.action_info/1" do
    test "returns a map with all fields populated" do
      assert {:ok, info} = ProGen.Actions.action_info("run")
      assert info.module == ProGen.Action.Run
      assert info.name == "run"
      assert info.description == "Run a system command"
      assert is_list(info.option_schema)
      assert Keyword.has_key?(info.option_schema, :command)
      assert is_binary(info.usage)
    end
  end
end
