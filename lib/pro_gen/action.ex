defmodule ProGen.Action do
  @moduledoc """
  Behavior for all actions.

  Defines one callback:

    * `perform/1` — Executes the action with validated keyword args

  Action metadata is declared via module attributes:

    * `@description`   — Short human-readable description (required)
    * `@option_schema` — NimbleOptions schema describing accepted options (defaults to `[]`)

  Using this module injects:

    * `name/0`          — Auto-derived namespaced action name (string, e.g. `"test.echo"`)
    * `description/0`   — Returns the declared description
    * `option_schema/0` — Returns the declared option schema
    * `validate_args/1`  — Validates a keyword list against the schema
    * `usage/0`          — Auto-generated usage text from the schema (overridable)
  """

  @callback perform(args :: keyword()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour ProGen.Action

      Module.register_attribute(__MODULE__, :description, persist: true)
      Module.register_attribute(__MODULE__, :option_schema, persist: true)

      @before_compile ProGen.Action

      @doc """
      Validates `args` against this action's `option_schema/0`.

      Returns `{:ok, validated_args}` or `{:error, %NimbleOptions.ValidationError{}}`.
      """
      def validate_args(args) do
        NimbleOptions.validate(args, option_schema())
      end

      @doc """
      Auto-generated usage text derived from `option_schema/0`.
      Override this function to provide custom usage text.
      """
      def usage do
        NimbleOptions.docs(option_schema())
      end

      defoverridable usage: 0
    end
  end

  defmacro __before_compile__(env) do
    description = Module.get_attribute(env.module, :description)
    option_schema = Module.get_attribute(env.module, :option_schema) || []

    unless description do
      raise CompileError,
        description:
          "module #{inspect(env.module)} must set @description when using ProGen.Action"
    end

    name =
      env.module
      |> Module.split()
      |> Enum.drop(2)
      |> Enum.map(&Macro.underscore/1)
      |> Enum.join(".")

    quote do
      def name, do: unquote(name)
      def description, do: unquote(description)
      def option_schema, do: unquote(Macro.escape(option_schema))
    end
  end
end
