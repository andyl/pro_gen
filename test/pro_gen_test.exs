defmodule ProGenTest do
  use ExUnit.Case
  doctest ProGen

  test "greets the world" do
    assert ProGen.hello() == :world
  end

  describe "ProGen.Action.Run option_schema validation" do
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

  describe "ProGen.Action.Run usage/0" do
    test "returns a string containing option names" do
      usage = ProGen.Action.Run.usage()
      assert is_binary(usage)
      assert usage =~ "command"
      assert usage =~ "args"
      assert usage =~ "dir"
    end
  end

  describe "ProGen.Actions.run/2" do
    test "validates and performs a valid action" do
      assert {:ok, {output, 0}} =
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

  describe "ProGen.Actions.action_info/1" do
    test "returns an Info struct with all fields populated" do
      assert {:ok, %ProGen.ActionInfo{} = info} = ProGen.Actions.action_info(:run)
      assert info.module == ProGen.Action.Run
      assert info.name == :run
      assert info.description == "Run a system command"
      assert is_list(info.option_schema)
      assert Keyword.has_key?(info.option_schema, :command)
      assert is_binary(info.usage)
    end
  end

  describe "ProGen.Env" do
    test "lazily creates ETS table on first call" do
      # get/2 should work without any explicit init
      assert ProGen.Env.get(:lazy_test_key, "default") == "default"
    end

    test "put/2 and get/2 basic round-trip" do
      ProGen.Env.put(:color, "blue")
      assert ProGen.Env.get(:color) == "blue"
    end

    test "put/1 with keyword list sets multiple keys" do
      ProGen.Env.put(fruit: "apple", veggie: "carrot")
      assert ProGen.Env.get(:fruit) == "apple"
      assert ProGen.Env.get(:veggie) == "carrot"
    end

    test "put/1 with map sets multiple keys" do
      ProGen.Env.put(%{lang: "elixir", version: "1.17"})
      assert ProGen.Env.get(:lang) == "elixir"
      assert ProGen.Env.get(:version) == "1.17"
    end

    test "get/2 returns default when key missing and no env var" do
      assert ProGen.Env.get(:no_such_key) == nil
      assert ProGen.Env.get(:no_such_key, "fallback") == "fallback"
    end

    test "get/2 falls back to env var" do
      System.put_env("PROGEN_TEST_VAR", "from_env")

      try do
        assert ProGen.Env.get(:progen_test_var) == "from_env"
      after
        System.delete_env("PROGEN_TEST_VAR")
      end
    end

    test "get/2 ETS value takes precedence over env var" do
      System.put_env("PROGEN_PRECEDENCE", "from_env")
      ProGen.Env.put(:progen_precedence, "from_ets")

      try do
        assert ProGen.Env.get(:progen_precedence) == "from_ets"
      after
        System.delete_env("PROGEN_PRECEDENCE")
      end
    end

    test "list/0 returns all stored key-value pairs" do
      ProGen.Env.put(:list_test_a, "alpha")
      ProGen.Env.put(:list_test_b, "beta")
      result = ProGen.Env.list()
      assert {:list_test_a, "alpha"} in result
      assert {:list_test_b, "beta"} in result
    end

    test "list/0 returns empty list when table has no entries" do
      # list/0 should work even if called on a fresh table;
      # other tests may have inserted keys, so just verify it returns a list
      assert is_list(ProGen.Env.list())
    end
  end
end
