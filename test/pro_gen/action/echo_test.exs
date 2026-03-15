defmodule ProGen.Action.EchoTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  describe "ProGen.Action.Echo" do
    test "writes message to stdout and returns :ok" do
      output =
        capture_io(fn ->
          assert :ok = ProGen.Actions.run("echo", message: "hello")
        end)

      assert output == "hello\n"
    end

    test "rejects a list value for :message" do
      assert {:error, message} =
               ProGen.Actions.run("echo", message: ["not", "a", "string"])

      assert is_binary(message)
    end

    test "name/0 returns \"echo\"" do
      assert ProGen.Action.Echo.name() == "echo"
    end

    test "description/0 returns a non-empty string" do
      desc = ProGen.Action.Echo.description()
      assert is_binary(desc)
      assert desc != ""
    end

    test "option_schema/0 includes :message" do
      schema = ProGen.Action.Echo.option_schema()
      assert is_list(schema)
      assert Keyword.has_key?(schema, :message)
    end

    test "is auto-discovered by the registry" do
      assert "echo" in ProGen.Actions.list_actions()
    end
  end
end
