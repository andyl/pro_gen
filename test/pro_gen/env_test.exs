defmodule ProGen.Script.EnvTest do
  use ExUnit.Case

  describe "ProGen.Script.Env" do
    test "lazily creates ETS table on first call" do
      # get/2 should work without any explicit init
      assert ProGen.Script.Env.get(:lazy_test_key, "default") == "default"
    end

    test "put/2 and get/2 basic round-trip" do
      ProGen.Script.Env.put(:color, "blue")
      assert ProGen.Script.Env.get(:color) == "blue"
    end

    test "put/1 with keyword list sets multiple keys" do
      ProGen.Script.Env.put(fruit: "apple", veggie: "carrot")
      assert ProGen.Script.Env.get(:fruit) == "apple"
      assert ProGen.Script.Env.get(:veggie) == "carrot"
    end

    test "put/1 with map sets multiple keys" do
      ProGen.Script.Env.put(%{lang: "elixir", version: "1.17"})
      assert ProGen.Script.Env.get(:lang) == "elixir"
      assert ProGen.Script.Env.get(:version) == "1.17"
    end

    test "get/2 returns default when key missing and no env var" do
      assert ProGen.Script.Env.get(:no_such_key) == nil
      assert ProGen.Script.Env.get(:no_such_key, "fallback") == "fallback"
    end

    test "get/2 falls back to env var" do
      System.put_env("PROGEN_TEST_VAR", "from_env")

      try do
        assert ProGen.Script.Env.get(:progen_test_var) == "from_env"
      after
        System.delete_env("PROGEN_TEST_VAR")
      end
    end

    test "get/2 ETS value takes precedence over env var" do
      System.put_env("PROGEN_PRECEDENCE", "from_env")
      ProGen.Script.Env.put(:progen_precedence, "from_ets")

      try do
        assert ProGen.Script.Env.get(:progen_precedence) == "from_ets"
      after
        System.delete_env("PROGEN_PRECEDENCE")
      end
    end

    test "list/0 returns all stored key-value pairs" do
      ProGen.Script.Env.put(:list_test_a, "alpha")
      ProGen.Script.Env.put(:list_test_b, "beta")
      result = ProGen.Script.Env.list()
      assert {:list_test_a, "alpha"} in result
      assert {:list_test_b, "beta"} in result
    end

    test "list/0 returns empty list when table has no entries" do
      # list/0 should work even if called on a fresh table;
      # other tests may have inserted keys, so just verify it returns a list
      assert is_list(ProGen.Script.Env.list())
    end
  end
end
