defmodule ProGen.Action do
  @moduledoc """
  Behavior for all actions.

  Defines six callbacks, listed here in execution order:

    1. `opts_def/0`    — NimbleOptions schema; args are validated first (default: `[]`)
    2. `depends_on/1`  — Dependencies run next (default: `[]`)
    3. `needed?/1`     — Skip check; `false` → `{:ok, :skipped}` (default: `true`)
    4. `validate/1`    — Precondition checks before perform (default: `[]`)
    5. `perform/1`     — Main execution with validated keyword args
    6. `confirm/2`     — Postcondition check after perform (default: `:ok`)

  When `needed?/1` returns `false`, the framework skips `perform/1` and returns
  `{:ok, :skipped}`. Pass `force: true` to `ProGen.Actions.run/2` to bypass the check.

  After `perform/1` succeeds, `confirm/2` is called with the raw perform result and
  the validated args. Return `:ok` to accept the result or `{:error, reason}` to
  signal a confirmation failure (wrapped as `{:error, {:confirmation_failed, reason}}`).

  The `validate/1` callback returns a list of `{validator_name, checks}` tuples
  declaring preconditions checked before `perform/1`. Each tuple is passed to
  `ProGen.Validations.run/2`. Example:

      @impl true
      def validate(_args), do: [{"filesys", [:has_mix, :has_git]}]

  Action metadata:

    * The description is derived from the first line of `@moduledoc` (required)

  Using this module injects:

    * `name/0`          — Auto-derived namespaced action name (string, e.g. `"test.echo"`)
    * `description/0`   — First line of `@moduledoc`
    * `validate_args/1`  — Validates a keyword list against the schema
    * `usage/0`          — Auto-generated usage text from the schema (overridable)
  """

  @callback opts_def() :: keyword()
  @callback depends_on(args :: keyword()) :: [String.t() | {String.t(), keyword()}]
  @callback needed?(args :: keyword()) :: boolean()
  @callback validate(args :: keyword()) :: [{String.t(), list()}]
  @callback perform(args :: keyword()) :: any()
  @callback confirm(result :: any(), args :: keyword()) :: :ok | {:error, term()}

  defmacro __using__(_opts) do
    quote do
      @behaviour ProGen.Action

      @before_compile ProGen.Action

      @doc """
      Returns the NimbleOptions schema for this action's arguments.
      Defaults to `[]` (no options).
      """
      def opts_def, do: []

      @doc """
      Validates `args` against this action's `opts_def/0`.

      Returns `{:ok, validated_args}` or `{:error, %NimbleOptions.ValidationError{}}`.
      """
      def validate_args(args) do
        NimbleOptions.validate(args, opts_def())
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
      Returns a list of `{validator_name, checks}` tuples declaring preconditions.
      Defaults to `[]`.
      """
      def validate(_args), do: []

      @doc """
      Postcondition check called after `perform/1`. Defaults to `:ok`.
      Override to verify the perform result before it is returned to callers.
      """
      def confirm(_result, _args), do: :ok

      @doc """
      Auto-generated usage text derived from `opts_def/0`.
      Override this function to provide custom usage text.
      """
      def usage do
        NimbleOptions.docs(opts_def())
      end

      defoverridable opts_def: 0, usage: 0, depends_on: 1, needed?: 1, validate: 1, confirm: 2
    end
  end

  defmacro __before_compile__(env) do
    moduledoc = Module.get_attribute(env.module, :moduledoc)

    doc_text =
      case moduledoc do
        {_line, text} when is_binary(text) -> text
        text when is_binary(text) -> text
        _ -> nil
      end

    unless doc_text do
      raise CompileError,
        description: "module #{inspect(env.module)} must set @moduledoc when using ProGen.Action"
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
    end
  end
end
