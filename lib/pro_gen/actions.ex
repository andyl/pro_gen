defmodule ProGen.Actions do
  @moduledoc """
  Central facade & registry for all ProGen actions.

  Actions are auto-discovered from modules whose name starts with `ProGen.Action.`.
  The action name is derived from the segments after `ProGen.Action`, downcased and
  dot-joined into a string (e.g. `ProGen.Action.Test.Echo` → `"test.echo"`).
  """

  # Cached results (list of action names + name → module map)
  @type action_map :: %{String.t() => module()}

  def list_actions do
    key = {__MODULE__, :actions_list}

    case :persistent_term.get(key, :none) do
      :none ->
        {list, _map} = compute_actions()
        :persistent_term.put(key, list)
        list

      cached ->
        cached
    end
  end

  def action_module(action_name) when is_binary(action_name) do
    key = {__MODULE__, :actions_map}

    map =
      case :persistent_term.get(key, :none) do
        :none ->
          {_list, map} = compute_actions()
          :persistent_term.put(key, map)
          map

        cached ->
          cached
      end

    Map.fetch(map, action_name)
  end

  def action_info(action_name) when is_binary(action_name) do
    case action_module(action_name) do
      {:ok, mod} ->
        {:ok,
         %{
           module: mod,
           name: mod.name(),
           description: mod.description(),
           option_schema: mod.option_schema(),
           usage: mod.usage()
         }}

      :error ->
        {:error, "Unknown action: #{inspect(action_name)}"}
    end
  end

  @doc """
  Validates args against the action's schema, then calls `perform/1`.

  Returns `:ok` on success or `{:error, message}` on failure.
  """
  def run(action_name, args \\ []) when is_binary(action_name) do
    case action_module(action_name) do
      {:ok, mod} ->
        case mod.validate_args(args) do
          {:ok, validated_args} ->
            mod.perform(validated_args)

          {:error, %NimbleOptions.ValidationError{} = error} ->
            {:error, Exception.message(error)}
        end

      :error ->
        {:error, "Unknown action: #{inspect(action_name)}"}
    end
  end

  # ---------------------------------------------------------------------------
  # Internal computation – only runs once (lazily)
  # ---------------------------------------------------------------------------

  defp compute_actions do
    prefix = ~c"Elixir.ProGen.Action."

    all_modules =
      for {app, _, _} <- Application.loaded_applications(),
          {:ok, mods} = :application.get_key(app, :modules),
          mod <- mods,
          do: mod

    # Filter only modules under ProGen.Action.*
    action_modules =
      for mod <- all_modules,
          mod_str = Atom.to_charlist(mod),
          :lists.prefix(prefix, mod_str),
          do: mod

    build_action_map(action_modules)
  end

  @doc false
  def build_action_map(action_modules) do
    name_to_mod =
      action_modules
      |> Enum.group_by(&action_name_from_module/1)
      |> Enum.map(fn
        {name, [mod]} ->
          {name, mod}

        {name, duplicates} ->
          raise ArgumentError,
                """
                Duplicate action name detected: "#{name}"

                Conflicting modules:
                #{duplicates |> Enum.map(&inspect/1) |> Enum.join("\n  ")}
                """
      end)
      |> Map.new()

    sorted_list = Map.keys(name_to_mod) |> Enum.sort()

    {sorted_list, name_to_mod}
  end

  @doc false
  def action_name_from_module(mod) do
    mod
    |> Module.split()
    |> Enum.drop(2)
    |> Enum.map(&Macro.underscore/1)
    |> Enum.join(".")
  end
end
