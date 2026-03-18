defmodule ProGen.Action.IO.InspectTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  describe "ProGen.Action.IO.Inspect" do
    test "inspects a map to stdout and returns :ok" do
      output =
        capture_io(fn ->
          assert :ok = ProGen.Actions.run("io.inspect", element: %{a: 1})
        end)

      assert output == "%{a: 1}\n"
    end

    test "inspects a list to stdout and returns :ok" do
      output =
        capture_io(fn ->
          assert :ok = ProGen.Actions.run("io.inspect", element: [1, 2, 3])
        end)

      assert output == "[1, 2, 3]\n"
    end

    test "inspects a string to stdout and returns :ok" do
      output =
        capture_io(fn ->
          assert :ok = ProGen.Actions.run("io.inspect", element: "hello")
        end)

      assert output == "\"hello\"\n"
    end

    test "returns error when :element is missing" do
      assert {:error, message} = ProGen.Actions.run("io.inspect", [])
      assert is_binary(message)
      assert message =~ "element"
    end

    test "name/0 returns \"io.inspect\"" do
      assert ProGen.Action.IO.Inspect.name() == "io.inspect"
    end

    test "description/0 returns a non-empty string" do
      desc = ProGen.Action.IO.Inspect.description()
      assert is_binary(desc)
      assert desc != ""
    end

    test "opts_def/0 includes :element" do
      schema = ProGen.Action.IO.Inspect.opts_def()
      assert is_list(schema)
      assert Keyword.has_key?(schema, :element)
    end

    test "is auto-discovered by the registry" do
      assert {"io.inspect", "Inspect an Elixir term to stdout."} in ProGen.Actions.list_actions()
    end
  end
end
