defmodule ProGen.ActionCommitTypeTest do
  use ExUnit.Case

  describe "commit_type/0" do
    test "action with @commit_type \"feat\" returns \"feat\"" do
      assert ProGen.Action.Test.CcFeat.commit_type() == "feat"
    end

    test "action with @commit_type \"docs(api)\" returns \"docs(api)\"" do
      assert ProGen.Action.Test.CcDocsApi.commit_type() == "docs(api)"
    end

    test "action without @commit_type returns default \"chore(action)\"" do
      assert ProGen.Action.Test.CcDefault.commit_type() == "chore(action)"
    end
  end

  describe "@commit_type validation" do
    test "invalid @commit_type raises CompileError at compile time" do
      code = """
      defmodule ProGen.Action.Test.CcInvalid do
        @moduledoc "Action with invalid commit type"
        use ProGen.Action
        @commit_type "badtype"
        @impl true
        def perform(_args), do: :ok
      end
      """

      assert_raise CompileError, ~r/invalid @commit_type/, fn ->
        Code.compile_string(code)
      end
    end

    test "invalid @commit_type with scope raises CompileError" do
      code = """
      defmodule ProGen.Action.Test.CcInvalidScoped do
        @moduledoc "Action with invalid scoped commit type"
        use ProGen.Action
        @commit_type "yolo(scope)"
        @impl true
        def perform(_args), do: :ok
      end
      """

      assert_raise CompileError, ~r/invalid @commit_type/, fn ->
        Code.compile_string(code)
      end
    end
  end

  describe "commit_type in action_info" do
    test "action_info includes commit_type" do
      {:ok, info} = ProGen.Actions.action_info("test.cc_feat")
      assert info.commit_type == "feat"
    end

    test "action_info includes default commit_type" do
      {:ok, info} = ProGen.Actions.action_info("test.cc_default")
      assert info.commit_type == "chore(action)"
    end
  end
end
