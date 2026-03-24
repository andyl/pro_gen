defmodule ProGen.Config do
  @moduledoc """
  Reads and parses project configuration from `.progen.yml` / `.progen.yaml`.

  The config file is expected to be in the current working directory
  (which follows `ProGen.Script.cd/1` if used). The file is read fresh
  on each call — no caching — so directory changes are respected.

  Currently supported keys:

    * `use_conventional_commits` (boolean, default `false`)

  """

  @defaults %{use_conventional_commits: false}

  @config_files [".progen.yml", ".progen.yaml"]

  @doc """
  Reads the project configuration from `.progen.yml` or `.progen.yaml`.

  Returns `{:ok, map}` with atom keys and defaults merged,
  or `{:error, reason}` on malformed YAML or invalid values.
  If no config file exists, returns `{:ok, defaults}`.
  """
  @spec read() :: {:ok, map()} | {:error, String.t()}
  def read do
    case find_config_file() do
      nil ->
        {:ok, @defaults}

      path ->
        case YamlElixir.read_from_file(path) do
          {:ok, nil} ->
            {:ok, @defaults}

          {:ok, parsed} when is_map(parsed) ->
            validate_config(parsed)

          {:ok, _} ->
            {:error, "config file must contain a YAML mapping"}

          {:error, %YamlElixir.ParsingError{} = e} ->
            {:error, "failed to parse #{path}: #{Exception.message(e)}"}
        end
    end
  end

  @doc """
  Returns whether conventional commits are enabled.

  Convenience wrapper around `read/0`. Returns `false` on error or missing file.
  """
  @spec use_conventional_commits?() :: boolean()
  def use_conventional_commits? do
    case read() do
      {:ok, %{use_conventional_commits: value}} -> value
      _ -> false
    end
  end

  # --- Private helpers ---

  defp find_config_file do
    Enum.find(@config_files, fn name ->
      File.regular?(name)
    end)
  end

  defp validate_config(parsed) do
    cc_value = Map.get(parsed, "use_conventional_commits")

    case cc_value do
      nil ->
        {:ok, @defaults}

      value when is_boolean(value) ->
        {:ok, %{@defaults | use_conventional_commits: value}}

      other ->
        {:error,
         "use_conventional_commits must be a boolean (true/false), got: #{inspect(other)}"}
    end
  end
end
