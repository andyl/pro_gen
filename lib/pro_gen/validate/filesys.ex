defmodule ProGen.Validate.Filesys do
  @moduledoc """
  Basic filesystem and toolchecks.

  Provides built-in validation checks for common preconditions:
  file existence, directory existence, etc.

  Use `checks/0` to discover available checks at runtime.
  """

  use ProGen.Validate
  alias ProGen.Validate

  defcheck :has_docker do
    desc "Pass if 'docker' exists"
    fail "Docker executable does not exist"
      test fn _ -> System.find_executable("docker") != nil end
  end

  defcheck :no_docker do
    desc "Pass if 'docker' does not exist"
    fail "Docker executable exists"
    test fn _ -> not eval_test(:has_docker) end
  end

  defcheck :has_mix do
    desc "Pass if 'mix.exs' exists"
    fail "File 'mix.exs' does not exist"
    test fn _ -> Validate.Mix.eval_test(:has_mixfile) end
  end

  defcheck :no_mix do
    desc "Pass if 'mix.exs' does not exist"
    fail "File 'mix.exs' already exists"
    test fn _ -> not eval_test(:has_mix) end
  end

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

  defcheck {:has_file, "file"} do
    desc "Pass if <file> exists"
    fail fn {:has_file, path} -> "File '#{path}' not found" end
    test fn {:has_file, path} -> File.exists?(path) end
  end

  defcheck {:no_file, "file"} do
    desc "Pass if <file> does not exist"
    fail fn {:no_file, path} -> "File '#{path}' already exists" end
    test fn {:no_file, path} -> not eval_test({:has_file, path}) end
  end

  defcheck {:has_dir, "dir"} do
    desc "Pass if <dir> exists"
    fail fn {:has_dir, path} -> "Directory '#{path}' not found" end
    test fn {:has_dir, path} -> File.dir?(path) end
  end

  defcheck {:no_dir, "dir"} do
    desc "Pass if <dir> does not exist"
    fail fn {:no_dir, path} -> "Directory '#{path}' already exists" end
    test fn {:no_dir, path} -> not eval_test({:has_dir, path}) end
  end
end
