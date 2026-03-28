defmodule ProGen.Action do
  @moduledoc """
  Behavior for all actions.

  Defines six callbacks, listed here in execution order:

    1. `opts_def/0`    — Optional. NimbleOptions schema; args are validated first (default: `[]`)
    2. `depends_on/1`  — Optional. Dependencies run next (default: `[]`)
    3. `needed?/1`     — Optional. Skip check; `false` → `{:ok, :skipped}` (default: `true`)
    4. `validate/1`    — Optional. Precondition checks before perform (default: `[]`)
    5. `perform/1`     — Required. Main execution with validated keyword args
    6. `confirm/2`     — Optional. Postcondition check after perform (default: `:ok`)

  When `needed?/1` returns `false`, the framework skips `perform/1` but still
  calls `confirm/2` with `{:ok, :skipped}` as the result, allowing side-effects
  like directory changes to occur even on skip. The overall return value is
  `{:ok, :skipped}`. Pass `force: true` to `ProGen.Actions.run/2` to bypass the check.

  `confirm/2` is called after `perform/1` succeeds (with the raw perform result)
  or after a skip (with `{:ok, :skipped}`). Return `:ok` to accept, `{:ok, opts}`
  to accept with side-effects (e.g., `{:ok, cd: path}` changes the working
  directory before follow-on actions), or `{:error, reason}` to signal a
  confirmation failure (wrapped as `{:error, {:confirmation_failed, reason}}`).

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
    * `commit_type/0`   — Conventional Commits type (default `"chore(action)"`, overridable via `@commit_type`)
    * `validate_args/1`  — Validates a keyword list against the schema
    * `usage/0`          — Auto-generated usage text from the schema (overridable)
  """

  @callback opts_def() :: keyword()
  @callback depends_on(args :: keyword()) :: [String.t() | {String.t(), keyword()}]
  @callback needed?(args :: keyword()) :: boolean()
  @callback validate(args :: keyword()) :: [{String.t(), list()}]
  @callback perform(args :: keyword()) :: any()
  @callback confirm(result :: any(), args :: keyword()) ::
              :ok | {:ok, keyword()} | {:error, term()}
  @callback commit_type() :: String.t()

  @valid_cc_types ~w(feat fix build chore ci docs style refactor perf revert test)

  defmacro __using__(_opts) do
    quote do
      @behaviour ProGen.Action

      Module.register_attribute(__MODULE__, :commit_type, accumulate: false)

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

    commit_type = Module.get_attribute(env.module, :commit_type)

    if commit_type do
      # Extract the bare type (before any parenthesized scope)
      bare_type =
        case String.split(commit_type, "(", parts: 2) do
          [type | _] -> type
          _ -> commit_type
        end

      valid_types = ProGen.Action.__valid_cc_types__()

      unless bare_type in valid_types do
        raise CompileError,
          description:
            "invalid @commit_type #{inspect(commit_type)} in #{inspect(env.module)}. " <>
              "Type must be one of: #{Enum.join(valid_types, ", ")}"
      end
    end

    resolved_commit_type = commit_type || "chore(action)"

    quote do
      def name, do: unquote(name)
      def description, do: unquote(description)
      def commit_type, do: unquote(resolved_commit_type)
    end
  end

  @doc false
  def __valid_cc_types__, do: @valid_cc_types
end
