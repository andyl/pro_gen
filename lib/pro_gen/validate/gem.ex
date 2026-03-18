defmodule ProGen.Validate.Gem do
  @moduledoc """
  Gem validator — bundles filesystem and hex tool checks.

  Provides built-in validation checks for common preconditions:
  file existence, directory existence, tool availability, etc.

  Use `checks/0` to discover available checks at runtime.
  """

  use ProGen.Validate

  @description "Bundled filesystem and hex tool checks"

  defcheck :has_mix do
    desc "Pass if mix.exs exists"
    fail "File 'mix.exs' not found"
    test fn _ -> File.exists?("mix.exs") end
  end

  defcheck :no_mix do
    desc "Pass if mix.exs does not exist"
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

  defcheck :has_igniter do
    desc "Pass if igniter is installed"
    fail "No igniter (install with 'mix archive.install hex igniter_new --force')"
    test fn _ -> elem(System.cmd("mix", ["help"]), 0) =~ "igniter" end
  end

  defcheck :no_igniter do
    desc "Pass if igniter is not installed"
    fail "Igniter is installed"
    test fn _ -> not eval_test(:has_igniter) end
  end

  defcheck :has_phx_new do
    desc "Pass if phx_new is installed"
    fail "No phx_new (install with 'mix archive.install hex phx_new_new --force')"
    test fn _ -> elem(System.cmd("mix", ["help"]), 0) =~ "phx.new" end
  end

  defcheck :no_phx_new do
    desc "Pass if phx_new is not installed"
    fail "phx_new is installed"
    test fn _ -> not eval_test(:has_phx_new) end
  end
end
