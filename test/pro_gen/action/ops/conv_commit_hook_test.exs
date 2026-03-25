defmodule ProGen.Action.Ops.ConvCommitHookTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias ProGen.Action.Ops.ConvCommitHook

  setup do
    original_dir = File.cwd!()

    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "pro_gen_test_conv_commit_hook_#{:erlang.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)
    File.cd!(tmp_dir)

    # Create mix.exs and .git so filesys validation passes
    File.write!("mix.exs", "defmodule Test.MixProject do\nend\n")

    capture_io(fn ->
      System.cmd("git", ["init"])
    end)

    on_exit(fn ->
      File.cd!(original_dir)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "needed?/1" do
    test "returns true when hook files do not exist" do
      assert ConvCommitHook.needed?([]) == true
    end

    test "returns true when only .githooks/commit-msg exists" do
      File.mkdir_p!(".githooks")
      File.write!(".githooks/commit-msg", "#!/bin/bash")
      assert ConvCommitHook.needed?([]) == true
    end

    test "returns true when only bin/install-git-hooks.sh exists" do
      File.mkdir_p!("bin")
      File.write!("bin/install-git-hooks.sh", "#!/bin/bash")
      assert ConvCommitHook.needed?([]) == true
    end

    test "returns false when both hook files exist" do
      File.mkdir_p!(".githooks")
      File.write!(".githooks/commit-msg", "#!/bin/bash")
      File.mkdir_p!("bin")
      File.write!("bin/install-git-hooks.sh", "#!/bin/bash")
      assert ConvCommitHook.needed?([]) == false
    end
  end

  describe "perform/1" do
    test "creates .githooks/commit-msg" do
      capture_io(fn ->
        assert :ok = ConvCommitHook.perform([])
      end)

      assert File.exists?(".githooks/commit-msg")
    end

    test "creates bin/install-git-hooks.sh" do
      capture_io(fn ->
        assert :ok = ConvCommitHook.perform([])
      end)

      assert File.exists?("bin/install-git-hooks.sh")
    end

    test "makes hook files executable" do
      capture_io(fn ->
        ConvCommitHook.perform([])
      end)

      %{mode: hook_mode} = File.stat!(".githooks/commit-msg")
      assert Bitwise.band(hook_mode, 0o111) != 0

      %{mode: script_mode} = File.stat!("bin/install-git-hooks.sh")
      assert Bitwise.band(script_mode, 0o111) != 0
    end

    test "appends git hooks section to README.md when it exists" do
      File.write!("README.md", "# My Project\n")

      capture_io(fn ->
        ConvCommitHook.perform([])
      end)

      readme = File.read!("README.md")
      assert readme =~ "## Git Hooks"
      assert readme =~ "Conventional Commit"
      assert readme =~ "install-git-hooks.sh"
    end

    test "does not fail when README.md does not exist" do
      capture_io(fn ->
        assert :ok = ConvCommitHook.perform([])
      end)

      refute File.exists?("README.md")
    end

    test "prints confirmation messages" do
      output =
        capture_io(fn ->
          ConvCommitHook.perform([])
        end)

      assert output =~ "Git hooks have been installed"
      assert output =~ "Conventional Commit messages are enforced"
    end
  end

  describe "confirm/2" do
    test "returns :ok when both files exist" do
      File.mkdir_p!(".githooks")
      File.write!(".githooks/commit-msg", "#!/bin/bash")
      File.mkdir_p!("bin")
      File.write!("bin/install-git-hooks.sh", "#!/bin/bash")

      assert :ok = ConvCommitHook.confirm(:ok, [])
    end

    test "returns error when .githooks/commit-msg is missing" do
      File.mkdir_p!("bin")
      File.write!("bin/install-git-hooks.sh", "#!/bin/bash")

      assert {:error, msg} = ConvCommitHook.confirm(:ok, [])
      assert msg =~ "commit-msg"
    end

    test "returns error when bin/install-git-hooks.sh is missing" do
      File.mkdir_p!(".githooks")
      File.write!(".githooks/commit-msg", "#!/bin/bash")

      assert {:error, msg} = ConvCommitHook.confirm(:ok, [])
      assert msg =~ "install-git-hooks.sh"
    end
  end

  describe "run via Actions.run/2" do
    test "full pipeline creates all files and succeeds" do
      capture_io(fn ->
        assert :ok = ProGen.Actions.run("ops.conv_commit_hook")
      end)

      assert File.exists?(".githooks/commit-msg")
      assert File.exists?("bin/install-git-hooks.sh")
    end

    test "skips on second run" do
      capture_io(fn ->
        assert :ok = ProGen.Actions.run("ops.conv_commit_hook")
      end)

      assert {:ok, :skipped} = ProGen.Actions.run("ops.conv_commit_hook")
    end
  end

  describe "module metadata" do
    test "name/0 returns the correct action name" do
      assert ConvCommitHook.name() == "ops.conv_commit_hook"
    end

    test "description/0 returns a non-empty string" do
      desc = ConvCommitHook.description()
      assert is_binary(desc)
      assert desc =~ "Conventional Commit"
    end
  end
end
