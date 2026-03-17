defmodule ProGen.Action.Git.InitTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  setup do
    original_dir = File.cwd!()
    tmp_dir = Path.join(System.tmp_dir!(), "pro_gen_test_git_init_#{:erlang.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)
    File.cd!(tmp_dir)

    on_exit(fn ->
      File.cd!(original_dir)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "run git.init" do
    test "initializes a git repo when .git does not exist" do
      capture_io(fn ->
        assert :ok = ProGen.Actions.run("git.init")
      end)

      assert File.dir?(".git")
    end

    test "skips when .git already exists" do
      capture_io(fn ->
        assert :ok = ProGen.Actions.run("git.init")
      end)

      assert {:ok, :skipped} = ProGen.Actions.run("git.init")
    end

    test "runs with force: true even when .git exists" do
      capture_io(fn ->
        assert :ok = ProGen.Actions.run("git.init")
      end)

      capture_io(fn ->
        assert :ok = ProGen.Actions.run("git.init", force: true)
      end)
    end
  end

  describe "needed?/1" do
    test "returns true when .git does not exist" do
      assert ProGen.Action.Git.Init.needed?([]) == true
    end

    test "returns false when .git exists" do
      capture_io(fn -> System.cmd("git", ["init"]) end)
      assert ProGen.Action.Git.Init.needed?([]) == false
    end
  end
end
