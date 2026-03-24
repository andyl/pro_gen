defmodule ProGen.Validate.Git do
  @moduledoc """
  Git repository validation checks.

  Provides checks for git repository state: existence, uncommitted changes,
  and unstaged files.

  Use `checks/0` to discover available checks at runtime.
  """

  use ProGen.Validate

  defcheck :has_git do
    desc "Pass if .git directory exists"
    fail "Directory '.git' not found"
    test fn _ -> File.dir?(".git") end
  end

  defcheck :no_git do
    desc "Pass if .git directory does not exist"
    fail "Directory '.git' already exists"
    test fn _ -> not eval_test(:has_git) end
  end

  defcheck :has_uncommitted do
    desc "Pass if repo has uncommitted changes"
    fail "No uncommitted changes found"
    test fn _ -> git_status_any?() end
  end

  defcheck :no_uncommitted do
    desc "Pass if repo has no uncommitted changes"
    fail "Uncommitted changes exist"
    test fn _ -> not eval_test(:has_uncommitted) end
  end

  defcheck :has_unstaged do
    desc "Pass if repo has unstaged files"
    fail "No unstaged files found"
    test fn _ -> git_has_unstaged?() end
  end

  defcheck :no_unstaged do
    desc "Pass if repo has no unstaged files"
    fail "Unstaged files exist"
    test fn _ -> not eval_test(:has_unstaged) end
  end

  # -----

  defp git_status_any? do
    case System.cmd("git", ["status", "--porcelain"], stderr_to_stdout: true) do
      {output, 0} -> String.trim(output) != ""
      _ -> false
    end
  end

  defp git_has_unstaged? do
    case System.cmd("git", ["diff", "--quiet"], stderr_to_stdout: true) do
      {_, 0} -> false
      {_, 1} -> true
      _ -> false
    end
  end
end
