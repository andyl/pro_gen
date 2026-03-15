defmodule ProGen.Validate.Basics do
  @moduledoc """
  Basic filesystem and tool checks.

  Provides 14 built-in validation checks for common preconditions:
  file existence, directory existence, tool availability, etc.

  Use `checks/0` to discover available checks at runtime.
  """

  use ProGen.Validate

  @description "Basic filesystem and tool checks"

  defp all_checks do
    [
      %{
        term: :has_mix,
        desc: "Pass if mix.exs exists",
        fail: "File 'mix.exs' not found",
        test: fn _ -> File.exists?("mix.exs") end
      },
      %{
        term: :no_mix,
        desc: "Pass if mix.exs does not exist",
        fail: "File 'mix.exs' already exists",
        test: fn _ -> not eval_test(:has_mix) end
      },
      %{
        term: :has_git,
        desc: "Pass if .git directory exists",
        fail: "Directory '.git' not found",
        test: fn _ -> File.dir?(".git") end
      },
      %{
        term: :no_git,
        desc: "Pass if .git directory does not exist",
        fail: "Directory '.git' already exists",
        test: fn _ -> not eval_test(:has_git) end
      },
      %{
        term: {:has_file, "file"},
        desc: "Pass if <file> exists",
        fail: fn {:has_file, path} -> "File '#{path}' not found" end,
        test: fn {:has_file, path} -> File.exists?(path) end
      },
      %{
        term: {:no_file, "file"},
        desc: "Pass if <file> does not exist",
        fail: fn {:no_file, path} -> "File '#{path}' already exists" end,
        test: fn {:no_file, path} -> not eval_test({:has_file, path}) end
      },
      %{
        term: {:has_dir, "dir"},
        desc: "Pass if <dir> exists",
        fail: fn {:has_dir, path} -> "Directory '#{path}' not found" end,
        test: fn {:has_dir, path} -> File.dir?(path) end
      },
      %{
        term: {:no_dir, "dir"},
        desc: "Pass if <dir> does not exist",
        fail: fn {:no_dir, path} -> "Directory '#{path}' already exists" end,
        test: fn {:no_dir, path} -> not eval_test({:has_dir, path}) end
      },
      %{
        term: :has_igniter,
        desc: "Pass if igniter is installed",
        fail: "No igniter (install with 'mix archive.install hex igniter_new --force')",
        test: fn _ -> elem(System.cmd("mix", ["help"]), 0) =~ "igniter" end
      },
      %{
        term: :no_igniter,
        desc: "Pass if igniter is not installed",
        fail: "Igniter is installed",
        test: fn _ -> not eval_test(:has_igniter) end
      },
      %{
        term: :has_phx_new,
        desc: "Pass if phx_new is installed",
        fail: "No phx_new (install with 'mix archive.install hex phx_new_new --force')",
        test: fn _ -> elem(System.cmd("mix", ["help"]), 0) =~ "phx.new" end
      },
      %{
        term: :no_phx_new,
        desc: "Pass if phx_new is not installed",
        fail: "phx_new is installed",
        test: fn _ -> not eval_test(:has_phx_new) end
      },
      %{
        term: :has_elixir,
        desc: "Pass if elixir is installed",
        fail: "No elixir - please install",
        test: fn _ -> System.find_executable("elixir") != nil end
      },
      %{
        term: :no_elixir,
        desc: "Pass if elixir is not installed",
        fail: "elixir is installed",
        test: fn _ -> not eval_test(:has_elixir) end
      }
    ]
  end
end
