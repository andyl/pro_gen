defmodule ProGen.Validate.Git do
  @moduledoc """
  TBD -- please update
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

  # More defchecks needed:
  # - has_uncommitted - Pass if repo has uncommitted files
  # - no_uncommitted - Pass if repo has no uncommitted files
  # - has_unstaged - Pass if repo has unstaged files
  # - no_unstaged - Pass if repo has no unstaged files
end
