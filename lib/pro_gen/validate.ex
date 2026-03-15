defmodule ProGen.Validate do
  @moduledoc """
  Behavior for validation modules.

  Defines two callbacks:

    * `checks/0`  — Returns a list of available check terms with descriptions
    * `check/1`   — Runs a single check term and returns `:ok` or `{:error, message}`

  Validation metadata is declared via module attributes:

    * `@description` — Short human-readable description (required)

  Using this module injects:

    * `name/0`          — Auto-derived validator name (string, e.g. `"basics"`)
    * `description/0`   — Returns the declared description
    * `option_schema/0` — Returns the option schema (`[checks: ...]`)
    * `validate_args/1`  — Validates a keyword list against the schema
    * `check/1`         — Default implementation that looks up term in `all_checks/0`
    * `checks/0`        — Default implementation that maps `all_checks/0` to `%{term:, desc:}`
    * `perform/1`       — Iterates check list via `Enum.reduce_while/3`, fail-fast
  """

  @callback checks() :: [%{term: atom() | tuple(), desc: String.t()}]
  @callback check(term :: atom() | tuple()) :: :ok | {:error, String.t()}

  defmacro __using__(_opts) do
    quote do
      @behaviour ProGen.Validate

      Module.register_attribute(__MODULE__, :description, persist: true)

      @before_compile ProGen.Validate

      def validate_args(args) do
        NimbleOptions.validate(args, option_schema())
      end

      def check(term) do
        case find_check(term) do
          nil ->
            {:error,
             "Unrecognized term (#{inspect(term)}), use #{inspect(__MODULE__)}.checks/0 for a list of valid terms"}

          entry ->
            if eval_test(term) do
              :ok
            else
              msg = if is_function(entry.fail), do: entry.fail.(term), else: entry.fail
              {:error, msg || "Error"}
            end
        end
      end

      def checks do
        Enum.map(all_checks(), fn entry -> Map.take(entry, [:term, :desc]) end)
      end

      def perform(args) do
        checks = Keyword.fetch!(args, :checks)

        Enum.reduce_while(checks, :ok, fn term, :ok ->
          case check(term) do
            :ok -> {:cont, :ok}
            {:error, _} = error -> {:halt, error}
          end
        end)
      end

      defoverridable check: 1, checks: 0, perform: 1

      defp eval_test(term) do
        case find_check(term) do
          nil -> raise "Error: unrecognized term (#{inspect(term)})"
          entry -> entry.test.(term)
        end
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
  end

  defmacro __before_compile__(env) do
    description = Module.get_attribute(env.module, :description)

    unless description do
      raise CompileError,
        description:
          "module #{inspect(env.module)} must set @description when using ProGen.Validate"
    end

    name =
      env.module
      |> Module.split()
      |> Enum.drop(2)
      |> Enum.map(&Macro.underscore/1)
      |> Enum.join(".")

    option_schema = [checks: [type: {:list, :any}, required: true, doc: "List of checks to run"]]

    quote do
      def name, do: unquote(name)
      def description, do: unquote(description)
      def option_schema, do: unquote(Macro.escape(option_schema))
    end
  end
end
