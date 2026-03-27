defmodule ProGen.Action.Ops.CommitHookTest do
  use ExUnit.Case

  alias ProGen.Action.Ops.CommitHook

  setup do
    original_dir = File.cwd!()

    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "pro_gen_test_commit_hook_#{:erlang.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)
    File.cd!(tmp_dir)

    # Create mix.exs and .git so filesys validation passes
    File.write!("mix.exs", "defmodule Test.MixProject do\nend\n")
    System.cmd("git", ["init"], stderr_to_stdout: true)

    on_exit(fn ->
      File.cd!(original_dir)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "needed?/1" do
    test "returns true when dep is missing and hook does not exist" do
      assert CommitHook.needed?([]) == true
    end

    test "returns true when dep is installed but hook does not exist" do
      File.write!("mix.exs", """
      defmodule Test.MixProject do
        defp deps do
          [{:commit_hook, "~> 0.1"}]
        end
      end
      """)

      assert CommitHook.needed?([]) == true
    end

    test "returns true when hook exists but dep is missing" do
      File.mkdir_p!(".git/hooks")
      File.write!(".git/hooks/commit-msg", "#!/bin/bash")
      assert CommitHook.needed?([]) == true
    end

    test "returns false when dep is installed and hook exists" do
      File.write!("mix.exs", """
      defmodule Test.MixProject do
        defp deps do
          [{:commit_hook, "~> 0.1"}]
        end
      end
      """)

      File.mkdir_p!(".git/hooks")
      File.write!(".git/hooks/commit-msg", "#!/bin/bash")
      assert CommitHook.needed?([]) == false
    end
  end

  describe "confirm/2" do
    test "returns :ok when .git/hooks/commit-msg exists" do
      File.mkdir_p!(".git/hooks")
      File.write!(".git/hooks/commit-msg", "#!/bin/bash")

      assert :ok = CommitHook.confirm(:ok, [])
    end

    test "returns error when .git/hooks/commit-msg is missing" do
      assert {:error, msg} = CommitHook.confirm(:ok, [])
      assert msg =~ "commit-msg"
    end
  end

  describe "module metadata" do
    test "name/0 returns the correct action name" do
      assert CommitHook.name() == "ops.commit_hook"
    end

    test "description/0 returns a non-empty string" do
      desc = CommitHook.description()
      assert is_binary(desc)
      assert desc =~ "Conventional Commit"
    end
  end
end
