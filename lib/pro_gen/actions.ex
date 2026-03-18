defmodule ProGen.Actions do
  @moduledoc """
  Central facade & registry for all ProGen actions.

  Actions are auto-discovered from modules whose name starts with `ProGen.Action.`.
  The action name is derived from the segments after `ProGen.Action`, downcased and
  dot-joined into a string (e.g. `ProGen.Action.Test.Echo` → `"test.echo"`).
  """

  alias ProGen.Util

  # Process dictionary keys for dependency resolution
  @ran_set_key :__pro_gen_ran_set__
  @resolving_stack_key :__pro_gen_resolving_stack__

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

  Returns `{:ok, map}` with `:module`, `:name`, `:description`, `:opts_def`,
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
           opts_def: mod.opts_def(),
           validate: mod.validate(),
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

  Dependencies declared via `depends_on/1` are resolved automatically before
  the action runs. Each dependency runs at most once per top-level `run/2` call
  (idempotent). Circular dependencies are detected and reported as errors.

  Options:

    * `force: true` — bypass the `needed?/1` check and always run the action.
      Does **not** propagate to dependencies.

  Returns the result of `perform/1`, `{:ok, :skipped}` when the action is not
  needed, or `{:error, message}` on failure.
  """
  def run(name_or_mod, args \\ [])

  def run(mod, args) when is_atom(mod) do
    top_level? = Process.get(@ran_set_key) == nil

    if top_level? do
      Process.put(@ran_set_key, MapSet.new())
      Process.put(@resolving_stack_key, [])
    end

    try do
      run_internal(mod, args)
    after
      if top_level? do
        Process.delete(@ran_set_key)
        Process.delete(@resolving_stack_key)
      end
    end
  end

  def run(action_name, args) when is_binary(action_name) do
    top_level? = Process.get(@ran_set_key) == nil

    if top_level? do
      Process.put(@ran_set_key, MapSet.new())
      Process.put(@resolving_stack_key, [])
    end

    try do
      run_internal(action_name, args)
    after
      if top_level? do
        Process.delete(@ran_set_key)
        Process.delete(@resolving_stack_key)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Internal runner with dependency resolution
  # ---------------------------------------------------------------------------

  defp run_internal(mod, args) when is_atom(mod) do
    with :ok <- ensure_loaded(mod),
         :ok <- ensure_action(mod) do
      action_name = mod.name()
      run_resolved(mod, action_name, args)
    end
  end

  defp run_internal(action_name, args) when is_binary(action_name) do
    case resolve_module(action_name) do
      {:ok, mod} -> run_resolved(mod, action_name, args)
      {:error, _} = err -> err
    end
  end

  defp resolve_module(action_name) do
    case action_module(action_name) do
      {:ok, mod} ->
        {:ok, mod}

      :error ->
        type = "action"
        list = ProGen.Actions.list_actions()
        {:error, Util.unk_term_error(type, action_name, list)}
    end
  end

  defp run_resolved(mod, action_name, args) do
    {force, action_args} = Keyword.pop(args, :force, false)
    ran_set = Process.get(@ran_set_key)
    stack = Process.get(@resolving_stack_key)

    # Idempotency: already ran in this top-level call
    if MapSet.member?(ran_set, action_name) do
      {:ok, :already_ran}
    else
      # Cycle detection
      if action_name in stack do
        cycle_path = Enum.reverse([action_name | stack]) |> Enum.join(" -> ")
        {:error, "Dependency cycle detected: #{cycle_path}"}
      else
        case mod.validate_args(action_args) do
          {:ok, validated_args} ->
            # Push onto resolving stack
            Process.put(@resolving_stack_key, [action_name | stack])

            # Resolve dependencies first
            case run_dependencies(mod, validated_args) do
              :ok ->
                result =
                  if force or mod.needed?(validated_args) do
                    case run_validations(mod) do
                      :ok -> perform_and_confirm(mod, validated_args)
                      {:error, _} = err -> err
                    end
                  else
                    {:ok, :skipped}
                  end

                # Record as ran and pop from stack
                Process.put(@ran_set_key, MapSet.put(Process.get(@ran_set_key), action_name))
                Process.put(@resolving_stack_key, stack)

                result

              {:error, _} = err ->
                # Pop from stack on failure
                Process.put(@resolving_stack_key, stack)
                err
            end

          {:error, %NimbleOptions.ValidationError{} = e} ->
            {:error, Exception.message(e)}
        end
      end
    end
  end

  defp run_dependencies(mod, validated_args) do
    deps = mod.depends_on(validated_args) |> normalize_deps()

    Enum.reduce_while(deps, :ok, fn {dep_name, dep_opts}, :ok ->
      case run_internal(dep_name, dep_opts) do
        {:error, reason} ->
          {:halt, {:error, "Dependency \"#{dep_name}\" failed: #{inspect(reason)}"}}

        _ok ->
          {:cont, :ok}
      end
    end)
  end

  defp normalize_deps(deps) do
    Enum.map(deps, fn
      {name, opts} when is_binary(name) and is_list(opts) -> {name, opts}
      name when is_binary(name) -> {name, []}
    end)
  end

  defp perform_and_confirm(mod, validated_args) do
    result = mod.perform(validated_args)

    case mod.confirm(result, validated_args) do
      :ok -> result
      {:error, reason} -> {:error, {:confirmation_failed, reason}}
    end
  end

  defp run_validations(mod) do
    mod.validate()
    |> Enum.reduce_while(:ok, fn {validator_name, checks}, :ok ->
      case ProGen.Validations.run(validator_name, checks: checks) do
        :ok -> {:cont, :ok}
        {:error, _} = err -> {:halt, err}
      end
    end)
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
