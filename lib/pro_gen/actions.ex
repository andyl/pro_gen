defmodule ProGen.Actions do
  @moduledoc """
  Central facade & registry for all ProGen actions.

  Actions are auto-discovered from modules whose name starts with `ProGen.Action.`.
  The action name is derived from the segments after `ProGen.Action`, downcased and
  dot-joined into a string (e.g. `ProGen.Action.Test.Echo` → `"test.echo"`).
  """

  alias ProGen.Util

  # Cached results (list of action names + name → module map)
  @type action_map :: %{String.t() => module()}

  @doc """
  Returns a sorted list of `{name, description}` tuples for all registered actions.
  """
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

  @doc """
  Looks up the module for the given action name.

  Returns `{:ok, module}` or `:error` if not found.
  """
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

  @doc """
  Returns metadata for the given action name.

  Returns `{:ok, map}` with `:module`, `:name`, `:description`, `:option_schema`,
  and `:usage` keys, or `{:error, message}` if not found.
  """
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
        type = "action"
        list = ProGen.Validations.list_validations()
        {:error, Util.unk_term_error(type, action_name, list)}
    end
  end

  @doc """
  Validates args against the action's schema, then calls `perform/1`.

  Accepts either a string name (looked up in the registry) or a module atom
  (used directly after verifying it implements `ProGen.Action`).

  Options:

    * `force: true` — bypass the `needed?/1` check and always run the action.

  Returns the result of `perform/1`, `{:ok, :skipped}` when the action is not
  needed, or `{:error, message}` on failure.
  """
  def run(name_or_mod, args \\ [])

  def run(mod, args) when is_atom(mod) do
    {force, action_args} = Keyword.pop(args, :force, false)

    with :ok <- ensure_loaded(mod),
         :ok <- ensure_action(mod) do
      case mod.validate_args(action_args) do
        {:ok, validated_args} ->
          if force or mod.needed?(validated_args) do
            mod.perform(validated_args)
          else
            {:ok, :skipped}
          end

        {:error, %NimbleOptions.ValidationError{} = e} ->
          {:error, Exception.message(e)}
      end
    end
  end

  def run(action_name, args) when is_binary(action_name) do
    {force, action_args} = Keyword.pop(args, :force, false)

    case action_module(action_name) do
      {:ok, mod} ->
        case mod.validate_args(action_args) do
          {:ok, validated_args} ->
            if force or mod.needed?(validated_args) do
              mod.perform(validated_args)
            else
              {:ok, :skipped}
            end

          {:error, %NimbleOptions.ValidationError{} = error} ->
            {:error, Exception.message(error)}
        end

      :error ->
        type = "action"
        list = ProGen.Actions.list_actions()
        {:error, Util.unk_term_error(type, action_name, list)}
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

    sorted_list =
      name_to_mod
      |> Enum.map(fn {name, mod} -> {name, mod.description()} end)
      |> Enum.sort_by(&elem(&1, 0))

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

  defp ensure_loaded(mod) do
    case Code.ensure_loaded(mod) do
      {:module, _} -> :ok
      {:error, _} -> {:error, "Module #{inspect(mod)} does not exist or could not be loaded"}
    end
  end

  defp ensure_action(mod) do
    behaviours =
      mod.module_info(:attributes)
      |> Keyword.get_values(:behaviour)
      |> List.flatten()

    if ProGen.Action in behaviours do
      :ok
    else
      {:error, "Module #{inspect(mod)} is not a ProGen.Action action"}
    end
  end
end
