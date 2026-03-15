defmodule ProGen.ActionsTest do
  use ExUnit.Case

  describe "ProGen.Actions.run/2" do
    test "validates and performs a valid action" do
      assert {output, 0} =
               ProGen.Actions.run(:run, command: "echo", args: ["hello"])

      assert String.trim(output) == "hello"
    end

    test "returns error for missing required args" do
      assert {:error, message} = ProGen.Actions.run(:run, [])
      assert is_binary(message)
      assert message =~ "command"
    end

    test "returns error for unknown action" do
      assert {:error, message} = ProGen.Actions.run(:nonexistent, [])
      assert message =~ "Unknown action"
    end
  end

  describe "ProGen.Actions.action_info/1" do
    test "returns a map with all fields populated" do
      assert {:ok, info} = ProGen.Actions.action_info(:run)
      assert info.module == ProGen.Action.Run
      assert info.name == :run
      assert info.description == "Run a system command"
      assert is_list(info.option_schema)
      assert Keyword.has_key?(info.option_schema, :command)
      assert is_binary(info.usage)
    end
  end
end
