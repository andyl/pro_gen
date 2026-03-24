defmodule ProGen.ScriptAutoCommitTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  setup do
    Application.put_env(:pro_gen, :auto_commit, true)

    original_dir = File.cwd!()

    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "pro_gen_test_auto_commit_#{:erlang.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)
    File.cd!(tmp_dir)

    # Initialize a git repo
    System.cmd("git", ["init"])
    System.cmd("git", ["config", "user.email", "test@test.com"])
    System.cmd("git", ["config", "user.name", "Test"])

    # Create initial commit so git log works
    File.write!(".gitkeep", "")
    System.cmd("git", ["add", "."])
    System.cmd("git", ["commit", "-m", "initial"])

    on_exit(fn ->
      Application.put_env(:pro_gen, :auto_commit, false)
      File.cd!(original_dir)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "command/2 auto-commit" do
    # test "creates a commit after successful command" do
    #   capture_io(fn ->
    #     ProGen.Script.command("Create file", "touch newfile.txt")
    #   end)
    #
    #   {log, 0} = System.cmd("git", ["log", "--format=%s"])
    #   assert log =~ "[ProGen] Create file"
    # end

    test "commit: false suppresses auto-commit" do
      capture_io(fn ->
        ProGen.Script.command("Create file", "touch newfile2.txt", commit: false)
      end)

      {log, 0} = System.cmd("git", ["log", "--format=%s"])
      refute log =~ "[ProGen] Create file"
    end
  end

  describe "action/3 auto-commit" do
    test "creates a commit after successful action" do
      # Write a file first so there's something to commit
      File.write!("action_test.txt", "test content")

      capture_io(fn ->
        ProGen.Script.action("Echo test", "io.echo", message: "hello")
      end)

      {log, 0} = System.cmd("git", ["log", "--format=%s"])
      assert log =~ "[ProGen] Echo test"
    end

    test "commit: false suppresses auto-commit" do
      File.write!("action_test2.txt", "test content")

      capture_io(fn ->
        ProGen.Script.action("Echo test", "io.echo", message: "hello", commit: false)
      end)

      {log, 0} = System.cmd("git", ["log", "--format=%s"])
      refute log =~ "[ProGen] Echo test"
    end
  end

  describe "conventional commits formatting" do
    test "CC enabled + action with custom @commit_type formats message" do
      File.write!(".progen.yml", "use_conventional_commits: true\n")
      File.write!("cc_test1.txt", "content")

      capture_io(fn ->
        ProGen.Script.action("Add feature", ProGen.Action.Test.CcFeat, [])
      end)

      {log, 0} = System.cmd("git", ["log", "--format=%s", "-1"])
      assert String.trim(log) == "feat: [ProGen] Add feature"
    end

    test "CC enabled + action without @commit_type uses default chore(action)" do
      File.write!(".progen.yml", "use_conventional_commits: true\n")
      File.write!("cc_test2.txt", "content")

      capture_io(fn ->
        ProGen.Script.action("Default type", ProGen.Action.Test.CcDefault, [])
      end)

      {log, 0} = System.cmd("git", ["log", "--format=%s", "-1"])
      assert String.trim(log) == "chore(action): [ProGen] Default type"
    end

    test "CC enabled + command uses chore(command)" do
      File.write!(".progen.yml", "use_conventional_commits: true\n")

      capture_io(fn ->
        ProGen.Script.command("Run setup", "touch cc_cmd.txt")
      end)

      {log, 0} = System.cmd("git", ["log", "--format=%s", "-1"])
      assert String.trim(log) == "chore(command): [ProGen] Run setup"
    end

    test "CC disabled (no config file) preserves legacy format" do
      File.write!("cc_test3.txt", "content")

      capture_io(fn ->
        ProGen.Script.action("Echo test", "io.echo", message: "hello")
      end)

      {log, 0} = System.cmd("git", ["log", "--format=%s", "-1"])
      assert String.trim(log) == "[ProGen] Echo test"
    end

    test "CC disabled (false) preserves legacy format" do
      File.write!(".progen.yml", "use_conventional_commits: false\n")
      File.write!("cc_test4.txt", "content")

      capture_io(fn ->
        ProGen.Script.action("Echo test", "io.echo", message: "hello")
      end)

      {log, 0} = System.cmd("git", ["log", "--format=%s", "-1"])
      assert String.trim(log) == "[ProGen] Echo test"
    end

    test "CC enabled + action by string name with custom @commit_type" do
      File.write!(".progen.yml", "use_conventional_commits: true\n")
      File.write!("cc_test5.txt", "content")

      capture_io(fn ->
        ProGen.Script.action("Docs update", "test.cc_docs_api", [])
      end)

      {log, 0} = System.cmd("git", ["log", "--format=%s", "-1"])
      assert String.trim(log) == "docs(api): [ProGen] Docs update"
    end
  end

  describe "auto-commit silently skips" do
    test "when no .git directory" do
      File.rm_rf!(".git")

      # Should not raise or fail
      capture_io(fn ->
        assert :ok = ProGen.Script.command("Create file", "touch nocommit.txt")
      end)
    end

    test "when tree is clean after command" do
      {log_before, 0} = System.cmd("git", ["log", "--oneline"])
      count_before = log_before |> String.trim() |> String.split("\n") |> length()

      capture_io(fn ->
        # echo doesn't modify files, so tree stays clean
        ProGen.Script.command("Echo only", "echo nothing")
      end)

      {log_after, 0} = System.cmd("git", ["log", "--oneline"])
      count_after = log_after |> String.trim() |> String.split("\n") |> length()

      assert count_after == count_before
    end
  end
end
