defmodule ProGen.Action.Validate do
  @moduledoc """
  Validates preconditions using declarative checks.

  Each check is an atom or tuple that maps to a built-in check function.
  Use `checks/0` to discover available checks at runtime.
  """

  use ProGen.Action

  @description "Validate preconditions using declarative checks"
  @option_schema [checks: [type: {:list, :any}, required: true, doc: "List of checks to run"]]

  defp all_checks do
    [
      %{
        term: :no_mix,
        desc: "Pass if mix.exs does not exist",
        fail: "mix.exs already exists",
        func: fn _ -> not File.exists?("mix.exs") end
      },
      %{
        term: :has_mix,
        desc: "Pass if mix.exs exists",
        fail: "mix.exs not found",
        func: fn _ -> File.exists?("mix.exs") end
      },
      %{
        term: :no_git,
        desc: "Pass if .git directory does not exist",
        fail: ".git already exists",
        func: fn _ -> not File.dir?(".git") end
      },
      %{
        term: :has_git,
        desc: "Pass if .git directory exists",
        fail: ".git not found",
        func: fn _ -> File.dir?(".git") end
      },
      %{
        term: {:no_file, "file"},
        desc: "Pass if <file> does not exist",
        fail: fn {:no_file, path} -> "#{path} already exists" end,
        func: fn {:no_file, path} -> not File.exists?(path) end
      },
      %{
        term: {:has_file, "file"},
        desc: "Pass if <file> exists",
        fail: fn {:has_file, path} -> "#{path} not found" end,
        func: fn {:has_file, path} -> File.exists?(path) end
      },
      %{
        term: {:no_dir, "dir"},
        desc: "Pass if <dir> does not exist",
        fail: fn {:no_dir, path} -> "#{path} already exists" end,
        func: fn {:no_dir, path} -> not File.dir?(path) end
      },
      %{
        term: {:has_dir, "dir"},
        desc: "Pass if <dir> exists",
        fail: fn {:has_dir, path} -> "#{path} not found" end,
        func: fn {:has_dir, path} -> File.dir?(path) end
      },
      %{
        term: {:dir_free, "dir"},
        desc: "Pass if <dir> exists and is empty",
        fail: fn {:dir_free, path} -> "#{path} is not an empty directory" end,
        func: fn {:dir_free, path} -> File.dir?(path) and File.ls!(path) == [] end
      }
    ]
  end

  @impl true
  def perform(args) do
    checks = Keyword.fetch!(args, :checks)

    Enum.reduce_while(checks, :ok, fn term, :ok ->
      case check(term) do
        :ok -> {:cont, :ok}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  @doc """
  Runs a single check term and returns `:ok` or `{:error, message}`.
  """
  def check(term) do
    case find_check(term) do
      nil ->
        {:error,
         "Unrecognized term (#{inspect(term)}), use ProGen.Action.Validate.checks/0 for a list of valid terms"}

      entry ->
        if entry.func.(term) do
          :ok
        else
          msg = if is_function(entry.fail), do: entry.fail.(term), else: entry.fail
          {:error, msg || "Error"}
        end
    end
  end

  @doc """
  Returns the list of available checks with `:term` and `:desc` keys.
  """
  def checks do
    Enum.map(all_checks(), fn entry -> Map.take(entry, [:term, :desc]) end)
  end

  defp find_check(check) when is_atom(check) do
    Enum.find(all_checks(), fn entry -> entry.term == check end)
  end

  defp find_check(check) when is_tuple(check) do
    tag = elem(check, 0)

    Enum.find(all_checks(), fn entry ->
      is_tuple(entry.term) and elem(entry.term, 0) == tag
    end)
  end
end
