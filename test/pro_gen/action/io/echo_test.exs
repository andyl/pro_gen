defmodule ProGen.Action.IO.EchoTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  describe "ProGen.Action.IO.Echo" do
    test "writes message to stdout and returns :ok" do
      output =
        capture_io(fn ->
          assert :ok = ProGen.Actions.run("io.echo", message: "hello")
        end)

      assert output == "hello\n"
    end

    test "rejects a list value for :message" do
      assert {:error, message} =
               ProGen.Actions.run("io.echo", message: ["not", "a", "string"])

      assert is_binary(message)
    end

    test "name/0 returns \"io.echo\"" do
      assert ProGen.Action.IO.Echo.name() == "io.echo"
    end

    test "description/0 returns a non-empty string" do
      desc = ProGen.Action.IO.Echo.description()
      assert is_binary(desc)
      assert desc != ""
    end

    test "opts_def/0 includes :message" do
      schema = ProGen.Action.IO.Echo.opts_def()
      assert is_list(schema)
      assert Keyword.has_key?(schema, :message)
    end

    test "is auto-discovered by the registry" do
      assert {"io.echo", "Echo a message to stdout."} in ProGen.Actions.list_actions()
    end
  end
end
