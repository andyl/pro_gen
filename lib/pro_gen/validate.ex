defmodule ProGen.Validate do
  @moduledoc """
  Behavior for validation modules.

  Defines two callbacks:

    * `checks/0`  — Returns a list of available check terms with descriptions
    * `check/1`   — Runs a single check term and returns `:ok` or `{:error, message}`

  Using this module injects:

    * `name/0`          — Auto-derived validator name (string, e.g. `"filesys"`)
    * `description/0`   — First line of `@moduledoc`
    * `opts_def/0` — Returns the option schema (`[checks: ...]`)
    * `validate_args/1`  — Validates a keyword list against the schema
    * `check/1`         — Default implementation that looks up term in `all_checks/0`
    * `checks/0`        — Default implementation that maps `all_checks/0` to `%{term:, desc:}`
    * `perform/1`       — Iterates check list via `Enum.reduce_while/3`, fail-fast

  ## `defcheck/2` macro

  Declares a validation check using a block DSL:

      defcheck :has_mix do
        desc "Pass if mix.exs exists"
        fail "File 'mix.exs' not found"
        test fn _ -> File.exists?("mix.exs") end
      end

  Each `defcheck` call accumulates compile-time metadata used to:
    * Auto-generate `defp all_checks/0`
    * Append a checks table to `@moduledoc`
  """

  alias ProGen.Xtool.StringUtil, as: Util

  @callback checks() :: [%{term: atom() | tuple(), desc: String.t()}]
  @callback check(term :: atom() | tuple()) :: :ok | {:error, String.t()}

  defmacro defcheck(term, do: block) do
    stmts =
      case block do
        {:__block__, _, stmts} -> stmts
        stmt -> [stmt]
      end

    opts =
      Enum.reduce(stmts, %{}, fn
        {:desc, _, [value]}, acc -> Map.put(acc, :desc, value)
        {:fail, _, [value]}, acc -> Map.put(acc, :fail, value)
        {:test, _, [value]}, acc -> Map.put(acc, :test, value)
      end)

    desc = Map.fetch!(opts, :desc)
    fail = Map.fetch!(opts, :fail)
    test_fn = Map.fetch!(opts, :test)

    map_ast =
      quote do
        %{term: unquote(term), desc: unquote(desc), fail: unquote(fail), test: unquote(test_fn)}
      end

    quote do
      @check_defs %{term: unquote(Macro.escape(term)), desc: unquote(desc)}
      @check_asts unquote(Macro.escape(map_ast))
    end
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour ProGen.Validate

      Module.register_attribute(__MODULE__, :check_defs, accumulate: true)
      Module.register_attribute(__MODULE__, :check_asts, accumulate: true)

      import ProGen.Validate, only: [defcheck: 2]

      @before_compile ProGen.Validate

      def validate_args(args) do
        NimbleOptions.validate(args, opts_def())
      end

      def check(term) do
        case find_check(term) do
          nil ->
            type = "term"
            list = __MODULE__.checks()
            {:error, Util.unk_term_error(type, term, list)}

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
        Enum.map(all_checks(), fn entry -> {inspect(entry.term), entry.desc} end)
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

      def eval_test(term) do
        case find_check(term) do
          nil -> raise "Unknown term #{inspect(term)}"
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
    moduledoc = Module.get_attribute(env.module, :moduledoc)

    doc_text =
      case moduledoc do
        {_line, text} when is_binary(text) -> text
        text when is_binary(text) -> text
        _ -> nil
      end

    unless doc_text do
      raise CompileError,
        description:
          "module #{inspect(env.module)} must set @moduledoc when using ProGen.Validate"
    end

    description = doc_text |> String.trim_leading() |> String.split("\n", parts: 2) |> hd()

    name =
      env.module
      |> Module.split()
      |> Enum.drop(2)
      |> Enum.map(&Macro.underscore/1)
      |> Enum.join(".")

    option_schema = [checks: [type: {:list, :any}, required: true, doc: "List of checks to run"]]

    # Accumulated attributes are in reverse order
    check_defs = env.module |> Module.get_attribute(:check_defs) |> Enum.reverse()
    check_asts = env.module |> Module.get_attribute(:check_asts) |> Enum.reverse()

    # Build markdown table for docs
    if check_defs != [] do
      base_doc = doc_text || ""

      rows =
        Enum.map_join(check_defs, "\n", fn %{term: term, desc: desc} ->
          "| `#{inspect(term)}` | #{desc} |"
        end)

      table = """

      ## Available Checks

      | Term | Description |
      |------|-------------|
      #{rows}
      """

      new_doc = String.trim_trailing(base_doc) <> "\n" <> table

      Module.put_attribute(env.module, :moduledoc, {1, new_doc})
    end

    quote do
      def name, do: unquote(name)
      def description, do: unquote(description)
      def opts_def, do: unquote(Macro.escape(option_schema))

      defp all_checks do
        unquote(check_asts)
      end
    end
  end
end
