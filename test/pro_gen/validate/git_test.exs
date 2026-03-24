defmodule ProGen.Validate.GitTest do
  use ExUnit.Case

  alias ProGen.Validate.Git

  @tmp_base Path.join(System.tmp_dir!(), "pro_gen_test_validate_git")

  setup do
    tmp = "#{@tmp_base}_#{:erlang.unique_integer([:positive])}"
    File.mkdir_p!(tmp)
    original_dir = File.cwd!()
    File.cd!(tmp)

    on_exit(fn ->
      File.cd!(original_dir)
      File.rm_rf!(tmp)
    end)

    {:ok, tmp: tmp}
  end

  defp git_init(tmp) do
    System.cmd("git", ["init"], cd: tmp)
    System.cmd("git", ["config", "user.email", "test@test.com"], cd: tmp)
    System.cmd("git", ["config", "user.name", "Test"], cd: tmp)
    File.write!(Path.join(tmp, "README.md"), "init")
    System.cmd("git", ["add", "."], cd: tmp)
    System.cmd("git", ["commit", "-m", "init"], cd: tmp)
  end

  describe "attribute accessors" do
    test "name/0 returns 'git'" do
      assert Git.name() == "git"
    end

    test "description/0 returns the module description" do
      assert Git.description() == "Git repository validation checks."
    end

    test "opts_def/0 includes :checks" do
      schema = Git.opts_def()
      assert is_list(schema)
      assert Keyword.has_key?(schema, :checks)
    end
  end

  describe ":has_git / :no_git" do
    test "has_git fails when no .git directory exists", %{tmp: _tmp} do
      assert {:error, _} = Git.check(:has_git)
    end

    test "no_git passes when no .git directory exists", %{tmp: _tmp} do
      assert :ok = Git.check(:no_git)
    end

    test "has_git passes when .git directory exists", %{tmp: tmp} do
      git_init(tmp)
      assert :ok = Git.check(:has_git)
    end

    test "no_git fails when .git directory exists", %{tmp: tmp} do
      git_init(tmp)
      assert {:error, _} = Git.check(:no_git)
    end
  end

  describe ":has_uncommitted / :no_uncommitted" do
    test "no_uncommitted passes on clean repo", %{tmp: tmp} do
      git_init(tmp)
      assert :ok = Git.check(:no_uncommitted)
    end

    test "has_uncommitted fails on clean repo", %{tmp: tmp} do
      git_init(tmp)
      assert {:error, _} = Git.check(:has_uncommitted)
    end

    test "has_uncommitted passes with staged changes", %{tmp: tmp} do
      git_init(tmp)
      File.write!(Path.join(tmp, "new.txt"), "content")
      System.cmd("git", ["add", "new.txt"], cd: tmp)
      assert :ok = Git.check(:has_uncommitted)
    end

    test "no_uncommitted fails with staged changes", %{tmp: tmp} do
      git_init(tmp)
      File.write!(Path.join(tmp, "new.txt"), "content")
      System.cmd("git", ["add", "new.txt"], cd: tmp)
      assert {:error, _} = Git.check(:no_uncommitted)
    end

    test "has_uncommitted passes with untracked files", %{tmp: tmp} do
      git_init(tmp)
      File.write!(Path.join(tmp, "untracked.txt"), "content")
      assert :ok = Git.check(:has_uncommitted)
    end
  end

  describe ":has_unstaged / :no_unstaged" do
    test "no_unstaged passes on clean repo", %{tmp: tmp} do
      git_init(tmp)
      assert :ok = Git.check(:no_unstaged)
    end

    test "has_unstaged fails on clean repo", %{tmp: tmp} do
      git_init(tmp)
      assert {:error, _} = Git.check(:has_unstaged)
    end

    test "has_unstaged passes with modified tracked file", %{tmp: tmp} do
      git_init(tmp)
      File.write!(Path.join(tmp, "README.md"), "modified")
      assert :ok = Git.check(:has_unstaged)
    end

    test "no_unstaged fails with modified tracked file", %{tmp: tmp} do
      git_init(tmp)
      File.write!(Path.join(tmp, "README.md"), "modified")
      assert {:error, _} = Git.check(:no_unstaged)
    end

    test "no_unstaged passes after staging all changes", %{tmp: tmp} do
      git_init(tmp)
      File.write!(Path.join(tmp, "README.md"), "modified")
      System.cmd("git", ["add", "."], cd: tmp)
      assert :ok = Git.check(:no_unstaged)
    end
  end

  describe "checks/0" do
    test "lists all available checks" do
      checks = Git.checks()
      names = Enum.map(checks, &elem(&1, 0))
      assert ":has_git" in names
      assert ":no_git" in names
      assert ":has_uncommitted" in names
      assert ":no_uncommitted" in names
      assert ":has_unstaged" in names
      assert ":no_unstaged" in names
    end
  end
end
