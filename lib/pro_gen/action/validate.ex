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
        desc: "Passes if mix.exs does not exist",
        func: fn _check ->
          if File.exists?("mix.exs"), do: {:error, "mix.exs already exists"}, else: :ok
        end
      },
      %{
        term: :has_mix,
        desc: "Passes if mix.exs exists",
        func: fn _check ->
          if File.exists?("mix.exs"), do: :ok, else: {:error, "mix.exs not found"}
        end
      },
      %{
        term: :no_git,
        desc: "Passes if .git directory does not exist",
        func: fn _check ->
          if File.dir?(".git"), do: {:error, ".git already exists"}, else: :ok
        end
      },
      %{
        term: :has_git,
        desc: "Passes if .git directory exists",
        func: fn _check ->
          if File.dir?(".git"), do: :ok, else: {:error, ".git not found"}
        end
      },
      %{
        term: :no_file,
        desc: "Passes if the given file does not exist",
        func: fn {:no_file, path} ->
          if File.exists?(path), do: {:error, "#{path} already exists"}, else: :ok
        end
      },
      %{
        term: :has_file,
        desc: "Passes if the given file exists",
        func: fn {:has_file, path} ->
          if File.exists?(path), do: :ok, else: {:error, "#{path} not found"}
        end
      },
      %{
        term: :no_dir,
        desc: "Passes if the given directory does not exist",
        func: fn {:no_dir, path} ->
          if File.dir?(path), do: {:error, "#{path} already exists"}, else: :ok
        end
      },
      %{
        term: :has_dir,
        desc: "Passes if the given directory exists",
        func: fn {:has_dir, path} ->
          if File.dir?(path), do: :ok, else: {:error, "#{path} not found"}
        end
      },
      %{
        term: :dir_free,
        desc: "Passes if the given directory exists and is empty",
        func: fn {:dir_free, path} ->
          cond do
            not File.dir?(path) -> {:error, "#{path} is not a directory"}
            File.ls!(path) != [] -> {:error, "#{path} is not empty"}
            true -> :ok
          end
        end
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
        entry.func.(term)
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
    Enum.find(all_checks(), fn entry -> entry.term == tag end)
  end
end
