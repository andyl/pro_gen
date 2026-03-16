defmodule ProGen.Validations do
  @moduledoc """
  Central facade & registry for all ProGen validators.

  Validators are auto-discovered from modules whose name starts with `ProGen.Validate.`.
  The validator name is derived from the segments after `ProGen.Validate`, downcased and
  dot-joined into a string (e.g. `ProGen.Validate.Basics` → `"basics"`).
  """

  @type validation_map :: %{String.t() => module()}

  alias ProGen.Util

  @doc """
  Returns a sorted list of `{name, description}` tuples for all registered validators.
  """
  def list_validations do
    key = {__MODULE__, :validations_list}

    case :persistent_term.get(key, :none) do
      :none ->
        {list, _map} = compute_validations()
        :persistent_term.put(key, list)
        list

      cached ->
        cached
    end
  end

  @doc """
  Looks up the module for the given validator name.

  Returns `{:ok, module}` or `:error` if not found.
  """
  def validation_module(name) when is_binary(name) do
    key = {__MODULE__, :validations_map}

    map =
      case :persistent_term.get(key, :none) do
        :none ->
          {_list, map} = compute_validations()
          :persistent_term.put(key, map)
          map

        cached ->
          cached
      end

    Map.fetch(map, name)
  end

  @doc """
  Returns metadata for the given validator name.

  Returns `{:ok, map}` with `:module`, `:name`, `:description`, and `:checks`
  keys, or `{:error, message}` if not found.
  """
  def validation_info(name) when is_binary(name) do
    case validation_module(name) do
      {:ok, mod} ->
        {:ok,
         %{
           module: mod,
           name: mod.name(),
           description: mod.description(),
           checks: mod.checks()
         }}

      :error ->
        {:error, "Unknown validator: #{inspect(name)}"}
    end
  end

  @doc """
  Validates args against the validator's schema, then calls `perform/1`.

  Returns `:ok` or `{:error, message}` on failure.
  """
  def run(name, args \\ []) when is_binary(name) do
    case validation_module(name) do
      {:ok, mod} ->
        case mod.validate_args(args) do
          {:ok, validated_args} ->
            mod.perform(validated_args)

          {:error, %NimbleOptions.ValidationError{} = error} ->
            {:error, Exception.message(error)}
        end

      :error ->
        type = "validator"
        list = ProGen.Validations.list_validations()
        {:error, Util.unk_term_error(type, name, list)}
    end
  end

  # ---------------------------------------------------------------------------
  # Internal computation – only runs once (lazily)
  # ---------------------------------------------------------------------------

  defp compute_validations do
    prefix = ~c"Elixir.ProGen.Validate."

    all_modules =
      for {app, _, _} <- Application.loaded_applications(),
          {:ok, mods} = :application.get_key(app, :modules),
          mod <- mods,
          do: mod

    validation_modules =
      for mod <- all_modules,
          mod_str = Atom.to_charlist(mod),
          :lists.prefix(prefix, mod_str),
          do: mod

    build_validation_map(validation_modules)
  end

  @doc false
  def build_validation_map(validation_modules) do
    name_to_mod =
      validation_modules
      |> Enum.group_by(&validation_name_from_module/1)
      |> Enum.map(fn
        {name, [mod]} ->
          {name, mod}

        {name, duplicates} ->
          raise ArgumentError,
                """
                Duplicate validator name detected: "#{name}"

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
  def validation_name_from_module(mod) do
    mod
    |> Module.split()
    |> Enum.drop(2)
    |> Enum.map(&Macro.underscore/1)
    |> Enum.join(".")
  end
end
