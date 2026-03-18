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

  describe "run/2 with module" do
    test "validates and performs a valid action module" do
      import ExUnit.CaptureIO

      assert capture_io(fn ->
               assert :ok = ProGen.Actions.run(ProGen.Action.Echo, message: "hello")
             end) == "hello\n"
    end

    test "returns error for missing required args" do
      assert {:error, msg} = ProGen.Actions.run(ProGen.Action.Echo, [])
      assert msg =~ "message"
    end

    test "returns error for non-existent module" do
      assert {:error, msg} = ProGen.Actions.run(ProGen.Action.DoesNotExist, [])
      assert msg =~ "does not exist or could not be loaded"
    end

    test "returns error for non-action module" do
      assert {:error, msg} = ProGen.Actions.run(String, [])
      assert msg =~ "is not a ProGen.Action action"
    end

    test "respects needed?/1 and force option" do
      assert {:ok, :skipped} = ProGen.Actions.run(ProGen.Action.Test.NeverNeeded, message: "hi")
      assert :ok = ProGen.Actions.run(ProGen.Action.Test.NeverNeeded, message: "hi", force: true)
    end
  end

  describe "duplicate detection" do
    test "raises ArgumentError when two modules derive to the same action name" do
      # Both modules produce "dup" after Enum.drop(2) — the first two segments differ
      # but the remainder is the same.
      Code.compile_string("""
      defmodule ProGen.Action.Dup do
        @moduledoc "First"
        use ProGen.Action
        @impl true
        def perform(_), do: :ok
      end
      """)

      Code.compile_string("""
      defmodule ProGen.FakeNs.Dup do
        @moduledoc "Second"
        use ProGen.Action
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

  describe "confirm/2 integration" do
    test "action with no confirm/2 override still works unchanged" do
      assert {output, 0} =
               ProGen.Actions.run("run", command: "echo", args: ["hello"])

      assert String.trim(output) == "hello"
    end

    test "action with confirm/2 returning :ok passes through perform result (string)" do
      assert {:ok, "hi"} =
               ProGen.Actions.run("test.confirm_pass", message: "hi")
    end

    test "action with confirm/2 returning :ok passes through perform result (module)" do
      assert {:ok, "hi"} =
               ProGen.Actions.run(ProGen.Action.Test.ConfirmPass, message: "hi")
    end

    test "action with confirm/2 returning error wraps as confirmation_failed (string)" do
      assert {:error, {:confirmation_failed, "boom"}} =
               ProGen.Actions.run("test.confirm_fail", message: "hi")
    end

    test "action with confirm/2 returning error wraps as confirmation_failed (module)" do
      assert {:error, {:confirmation_failed, "boom"}} =
               ProGen.Actions.run(ProGen.Action.Test.ConfirmFail, message: "hi")
    end

    test "confirm/2 is not called when action is skipped" do
      assert {:ok, :skipped} =
               ProGen.Actions.run("test.never_needed", message: "hi")
    end
  end

  describe "depends_on/1" do
    setup do
      Process.delete(:dep_base_count)
      Process.delete(:dep_child_ran)
      Process.delete(:dep_on_failing_ran)
      Process.delete(:dep_with_opts_args)
      Process.delete(:dep_conditional_ran)
      Process.delete(:dep_on_never_needed_ran)
      :ok
    end

    test "dependencies run before the action" do
      assert {:ok, :dep_child_ran} = ProGen.Actions.run("test.dep_child", [])
      assert Process.get(:dep_base_count) == 1
      assert Process.get(:dep_child_ran) == true
    end

    test "diamond: shared dependency runs exactly once" do
      assert {:ok, :diamond_ran} = ProGen.Actions.run("test.dep_diamond", [])
      assert Process.get(:dep_base_count) == 1
    end

    test "cycle detection returns clear error" do
      assert {:error, msg} = ProGen.Actions.run("test.dep_cycle_a", [])
      assert msg =~ "cycle"
      assert msg =~ "test.dep_cycle_a"
    end

    test "dependency failure stops parent action" do
      assert {:error, msg} = ProGen.Actions.run("test.dep_on_failing", [])
      assert msg =~ "Dependency"
      assert msg =~ "test.dep_failing"
      refute Process.get(:dep_on_failing_ran)
    end

    test "default depends_on/1 returns []" do
      assert ProGen.Action.Test.DepBase.depends_on([]) == []
    end

    test "dependencies receive their specified options" do
      assert {:ok, :dep_passes_opts_ran} = ProGen.Actions.run("test.dep_passes_opts", [])
      assert Process.get(:dep_with_opts_args) == [message: "from_parent"]
    end

    test "process dictionary cleaned up after run" do
      ProGen.Actions.run("test.dep_child", [])
      refute Process.get(:__pro_gen_ran_set__)
      refute Process.get(:__pro_gen_resolving_stack__)
    end

    test "force: true does not propagate to dependencies" do
      # dep_on_never_needed depends on test.never_needed which has needed?/1 -> false
      # force: true on the parent should NOT propagate to the dep,
      # so the dep should be skipped (but still recorded as ran)
      assert {:ok, :dep_on_never_needed_ran} =
               ProGen.Actions.run("test.dep_on_never_needed", message: "hi", force: true)

      assert Process.get(:dep_on_never_needed_ran) == true
    end

    test "conditional deps: depends_on/1 uses args" do
      # Without with_dep, no dependency runs
      Process.delete(:dep_base_count)
      assert {:ok, :dep_conditional_ran} = ProGen.Actions.run("test.dep_conditional", [])
      refute Process.get(:dep_base_count)

      # With with_dep: true, dependency runs
      Process.delete(:dep_base_count)

      assert {:ok, :dep_conditional_ran} =
               ProGen.Actions.run("test.dep_conditional", with_dep: true)

      assert Process.get(:dep_base_count) == 1
    end
  end

  describe "ProGen.Actions.action_info/1" do
    test "returns a map with all fields populated" do
      assert {:ok, info} = ProGen.Actions.action_info("run")
      assert info.module == ProGen.Action.Run
      assert info.name == "run"
      assert info.description == "Run a system command."
      assert is_list(info.option_schema)
      assert Keyword.has_key?(info.option_schema, :command)
      assert is_binary(info.usage)
    end
  end
end
