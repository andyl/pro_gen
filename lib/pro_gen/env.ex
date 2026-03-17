defmodule ProGen.Env do
  @moduledoc """
  An ETS-backed key-value store with environment variable fallback.

  Values are stored in a public named ETS table. The table is created lazily
  on the first `put` or `get` call — no explicit initialization is needed.
  When a key is not found in ETS, `get/2` falls back to checking OS environment
  variables before returning the default.
  """

  @table :app_globals

  @doc """
  Sets one or more key-value pairs.

  Accepts a keyword list, a map, or a single `key, value` pair.

  ## Examples

      ProGen.Env.put(:color, "blue")
      ProGen.Env.put(fruit: "apple", veggie: "carrot")
      ProGen.Env.put(%{lang: "elixir"})
  """
  def put(pairs) when is_list(pairs) do
    ensure_table()
    :ets.insert(@table, pairs)
    pairs
  end

  def put(pairs) when is_map(pairs) do
    ensure_table()
    :ets.insert(@table, Map.to_list(pairs))
    pairs
  end

  def put(key, value) do
    ensure_table()
    :ets.insert(@table, {key, value})
    value
  end

  @doc """
  Gets a value by key. Falls back to OS environment variables, then `default`.

  For atom keys, the env var name is the uppercased string form
  (e.g. `:database_url` → `"DATABASE_URL"`). String keys are used as-is.
  """
  def get(key, default \\ nil) do
    ensure_table()

    case :ets.lookup(@table, key) do
      [{^key, v}] ->
        v

      [] ->
        env_key =
          case key do
            k when is_atom(k) -> k |> Atom.to_string() |> String.upcase()
            k when is_binary(k) -> k
          end

        System.get_env(env_key) || default
    end
  end

  @doc """
  Returns all key-value pairs stored in the ETS table as a list of tuples.

  ## Examples

      ProGen.Env.put(color: "blue", lang: "elixir")
      ProGen.Env.list()
      #=> [color: "blue", lang: "elixir"]
  """
  def list do
    ensure_table()
    :ets.tab2list(@table)
  end

  defp ensure_table do
    case :ets.whereis(@table) do
      :undefined -> init_table()
      _ref -> :ok
    end
  end

  defp init_table do
    :ets.new(@table, [:set, :named_table, :public, read_concurrency: true])
    :ok
  rescue
    ArgumentError -> :ok
  end
end
