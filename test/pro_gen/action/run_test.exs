defmodule ProGen.Action.RunTest do
  use ExUnit.Case

  describe "Run option_schema validation" do
    test "accepts valid args" do
      args = [command: "echo", args: ["hello"], dir: "/tmp"]
      assert {:ok, validated} = ProGen.Action.Run.validate_args(args)
      assert validated[:command] == "echo"
      assert validated[:args] == ["hello"]
      assert validated[:dir] == "/tmp"
    end

    test "applies defaults for optional args" do
      args = [command: "echo"]
      assert {:ok, validated} = ProGen.Action.Run.validate_args(args)
      assert validated[:command] == "echo"
      assert validated[:args] == []
      assert validated[:dir] == "."
    end

    test "rejects missing required field" do
      assert {:error, %NimbleOptions.ValidationError{}} =
               ProGen.Action.Run.validate_args([])
    end

    test "rejects bad type for command" do
      assert {:error, %NimbleOptions.ValidationError{}} =
               ProGen.Action.Run.validate_args(command: 123)
    end

    test "rejects bad type for args" do
      assert {:error, %NimbleOptions.ValidationError{}} =
               ProGen.Action.Run.validate_args(command: "echo", args: "not_a_list")
    end
  end

  describe "Run usage/0" do
    test "returns a string containing option names" do
      usage = ProGen.Action.Run.usage()
      assert is_binary(usage)
      assert usage =~ "command"
      assert usage =~ "args"
      assert usage =~ "dir"
    end
  end
end
