defmodule ProGen.CodeMods.DepsTweaks do
  @moduledoc "Tweaks to dependency specs in mix.exs"

  @doc """
  Removes the `only:` option from a dependency in mix.exs.

  Raises if mix.exs is not found at the given path.

  Returns `{:ok, :updated}` if the option was removed,
  `{:ok, :already_set}` if no `only:` option was present,
  or `{:error, reason}` on failure.

  ## Options

    * `:path` - path to the mix.exs file (default: `"mix.exs"`)

  ## Examples

      remove_only("ex_doc")
      # {:ex_doc, "~> 0.31", only: :dev} → {:ex_doc, "~> 0.31"}

      remove_only("ex_doc")
      # {:ex_doc, "~> 0.31", only: :dev, runtime: false} → {:ex_doc, "~> 0.31", runtime: false}
  """
  def remove_only(dependency, opts \\ []) when is_binary(dependency) do
    path = resolve_path!(opts)
    source = File.read!(path)

    with {:ok, dep_match} <- find_dep_tuple(source, dependency) do
      only_pattern = ~r/,\s*only:\s*(?:\[[^\]]*\]|:\w+)/

      if Regex.match?(only_pattern, dep_match) do
        cleaned = Regex.replace(only_pattern, dep_match, "")
        new_source = String.replace(source, dep_match, cleaned, global: false)
        File.write!(path, new_source)
        {:ok, :updated}
      else
        {:ok, :already_set}
      end
    end
  end

  @doc """
  Sets the `only:` option on a dependency in mix.exs.

  Raises if mix.exs is not found at the given path.

  Returns `{:ok, :updated}` if the option was set,
  `{:ok, :already_set}` if `only:` already has the given value,
  or `{:error, reason}` on failure.

  ## Options

    * `:path` - path to the mix.exs file (default: `"mix.exs"`)

  ## Examples

      set_only("usage_rules", [:dev, :test])
      # {:usage_rules, "~> 0.2"} → {:usage_rules, "~> 0.2", only: [:dev, :test]}

      set_only("usage_rules", [:dev, :test])
      # {:usage_rules, "~> 0.2", only: :dev} → {:usage_rules, "~> 0.2", only: [:dev, :test]}
  """
  def set_only(dependency, envs, opts \\ []) when is_binary(dependency) do
    path = resolve_path!(opts)
    source = File.read!(path)
    envs_str = inspect(envs)

    with {:ok, dep_match} <- find_dep_tuple(source, dependency) do
      only_pattern = ~r/only:\s*(?:\[[^\]]*\]|:\w+)/

      if Regex.match?(only_pattern, dep_match) do
        if current_only_matches?(dep_match, envs_str) do
          {:ok, :already_set}
        else
          new_dep = Regex.replace(only_pattern, dep_match, "only: #{envs_str}")
          new_source = String.replace(source, dep_match, new_dep, global: false)
          File.write!(path, new_source)
          {:ok, :updated}
        end
      else
        new_dep = Regex.replace(~r/\}\s*$/, dep_match, ", only: #{envs_str}}")
        new_source = String.replace(source, dep_match, new_dep, global: false)
        File.write!(path, new_source)
        {:ok, :updated}
      end
    end
  end

  defp find_dep_tuple(source, dependency) do
    dep_str = Regex.escape(dependency)
    pattern = ~r/\{:#{dep_str},[^}]*\}/

    case Regex.run(pattern, source) do
      [match] -> {:ok, match}
      nil -> {:error, "dependency :#{dependency} not found in deps/0"}
    end
  end

  defp current_only_matches?(dep_match, envs_str) do
    case Regex.run(~r/only:\s*((?:\[[^\]]*\]|:\w+))/, dep_match, capture: :all_but_first) do
      [current] -> normalize(current) == normalize(envs_str)
      nil -> false
    end
  end

  defp normalize(str), do: String.replace(str, ~r/\s/, "")

  defp resolve_path!(opts) do
    path = Keyword.get(opts, :path, "mix.exs") |> Path.expand()
    unless File.exists?(path), do: raise("mix.exs not found at #{path}")
    path
  end
end
