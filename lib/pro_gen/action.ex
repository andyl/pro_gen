defmodule ProGen.Action do
  @moduledoc """
  Behavior for all actions.

  Defines four callbacks:

    * `depends_on/1` — Optional list of dependency action names to run first (default: `[]`)
    * `needed?/1`  — Optional predicate checked before `perform/1` (default: `true`)
    * `perform/1`  — Executes the action with validated keyword args
    * `confirm/2`  — Optional postcondition checked after `perform/1` (default: `:ok`)

  When `needed?/1` returns `false`, the framework skips `perform/1` and returns
  `{:ok, :skipped}`. Pass `force: true` to `ProGen.Actions.run/2` to bypass the check.

  After `perform/1` succeeds, `confirm/2` is called with the raw perform result and
  the validated args. Return `:ok` to accept the result or `{:error, reason}` to
  signal a confirmation failure (wrapped as `{:error, {:confirmation_failed, reason}}`).

  Action metadata:

    * The description is derived from the first line of `@moduledoc` (required)
    * `@option_schema` — [NimbleOptions](https://github.com/dashbitco/nimble_options) schema describing accepted options (defaults to `[]`)

  Using this module injects:

    * `name/0`          — Auto-derived namespaced action name (string, e.g. `"test.echo"`)
    * `description/0`   — First line of `@moduledoc`
    * `option_schema/0` — Returns the declared option schema
    * `validate_args/1`  — Validates a keyword list against the schema
    * `usage/0`          — Auto-generated usage text from the schema (overridable)
  """

  @callback depends_on(args :: keyword()) :: [String.t() | {String.t(), keyword()}]
  @callback needed?(args :: keyword()) :: boolean()
  @callback perform(args :: keyword()) :: any()
  @callback confirm(result :: any(), args :: keyword()) :: :ok | {:error, term()}

  defmacro __using__(_opts) do
    quote do
      @behaviour ProGen.Action

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
      Returns a list of dependency action names that must run before this action.
      Each element is either a string name or a `{name, opts}` tuple.
      Defaults to `[]`.
      """
      def depends_on(_args), do: []

      @doc """
      Returns whether this action needs to run. Defaults to `true`.
      Override to skip execution when the desired state already exists.
      """
      def needed?(_args), do: true

      @doc """
      Postcondition check called after `perform/1`. Defaults to `:ok`.
      Override to verify the perform result before it is returned to callers.
      """
      def confirm(_result, _args), do: :ok

      @doc """
      Auto-generated usage text derived from `option_schema/0`.
      Override this function to provide custom usage text.
      """
      def usage do
        NimbleOptions.docs(option_schema())
      end

      defoverridable usage: 0, depends_on: 1, needed?: 1, confirm: 2
    end
  end

  defmacro __before_compile__(env) do
    moduledoc = Module.get_attribute(env.module, :moduledoc)
    option_schema = Module.get_attribute(env.module, :option_schema) || []

    doc_text =
      case moduledoc do
        {_line, text} when is_binary(text) -> text
        text when is_binary(text) -> text
        _ -> nil
      end

    unless doc_text do
      raise CompileError,
        description:
          "module #{inspect(env.module)} must set @moduledoc when using ProGen.Action"
    end

    description = doc_text |> String.trim_leading() |> String.split("\n", parts: 2) |> hd()

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
