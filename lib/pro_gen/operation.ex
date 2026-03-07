defmodule ProGen.Operation do
  @moduledoc """
  Behavior for all operations.

  Defines three callbacks:

    * `perform/1`       — Executes the operation with validated keyword args
    * `description/0`   — Short human-readable description of what the operation does
    * `option_schema/0` — NimbleOptions schema describing accepted options

  Using this module injects:

    * `validate_args/1` — Validates a keyword list against the schema
    * `usage/0`         — Auto-generated usage text from the schema (overridable)
  """

  @callback perform(args :: keyword()) :: any()
  @callback description() :: String.t()
  @callback option_schema() :: keyword()

  defmacro __using__(_opts) do
    quote do
      @behaviour ProGen.Operation

      @doc """
      Validates `args` against this operation's `option_schema/0`.

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
end
