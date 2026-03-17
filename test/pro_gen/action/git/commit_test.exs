defmodule ProGen.Action.Git.CommitTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  setup do
    original_dir = File.cwd!()
    tmp_dir = Path.join(System.tmp_dir!(), "pro_gen_test_git_commit_#{:erlang.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)
    File.cd!(tmp_dir)

    # Initialize a git repo with initial config
    System.cmd("git", ["init"])
    System.cmd("git", ["config", "user.email", "test@test.com"])
    System.cmd("git", ["config", "user.name", "Test"])

    on_exit(fn ->
      File.cd!(original_dir)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "run git.commit" do
    test "commits when there are changes" do
      File.write!("test.txt", "hello")

      capture_io(fn ->
        assert :ok = ProGen.Actions.run("git.commit", message: "Initial commit")
      end)

      {log, 0} = System.cmd("git", ["log", "--oneline"])
      assert log =~ "Initial commit"
    end

    test "skips when tree is clean" do
      # Create an initial commit so the tree is clean
      File.write!("test.txt", "hello")
      System.cmd("git", ["add", "."])
      System.cmd("git", ["commit", "-m", "init"])

      assert {:ok, :skipped} = ProGen.Actions.run("git.commit", message: "No changes")
    end

    test "commit message matches provided :message option" do
      File.write!("test.txt", "hello")

      capture_io(fn ->
        assert :ok = ProGen.Actions.run("git.commit", message: "[ProGen] Test message")
      end)

      {log, 0} = System.cmd("git", ["log", "--format=%s", "-1"])
      assert String.trim(log) == "[ProGen] Test message"
    end

    test "skips when no .git directory" do
      File.rm_rf!(".git")
      assert {:ok, :skipped} = ProGen.Actions.run("git.commit", message: "No repo")
    end
  end

  describe "needed?/1" do
    test "returns false when tree is clean" do
      File.write!("test.txt", "hello")
      System.cmd("git", ["add", "."])
      System.cmd("git", ["commit", "-m", "init"])

      assert ProGen.Action.Git.Commit.needed?([]) == false
    end

    test "returns true when there are changes" do
      File.write!("test.txt", "hello")
      assert ProGen.Action.Git.Commit.needed?([]) == true
    end

    test "returns false when no .git directory" do
      File.rm_rf!(".git")
      assert ProGen.Action.Git.Commit.needed?([]) == false
    end
  end
end
