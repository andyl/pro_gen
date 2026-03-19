defmodule ProGen.CodeMods.MixFile do
  @moduledoc "Programmatic, idempotent modifications to mix.exs files."

  alias Sourceror.Zipper

  @doc """
  Adds a key-value entry to the `project/0` keyword list in a mix.exs file.

  The `value_code` parameter is a string of Elixir code (e.g., `"usage_rules()"`
  or `":my_app"`).

  Returns `{:ok, :updated}` if the entry was added, `{:ok, :already_exists}` if
  the key is already present, or `{:error, reason}` on failure.

  ## Options

    * `:path` - path to the mix.exs file (default: `"mix.exs"`)
  """
  def add_to_project(key, value_code, opts \\ []) when is_atom(key) and is_binary(value_code) do
    path = Keyword.get(opts, :path, "mix.exs") |> Path.expand()

    with {:ok, source} <- File.read(path),
         {:ok, zipper} <- parse_and_zip(source),
         {:ok, zipper} <- Igniter.Code.Function.move_to_def(zipper, :project, 0) do
      zipper = Igniter.Code.Common.maybe_move_to_single_child_block(zipper)

      case Igniter.Code.Keyword.get_key(zipper, key) do
        {:ok, _} ->
          {:ok, :already_exists}

        :error ->
          value_ast = Sourceror.parse_string!(value_code)

          val =
            with_clean_sourceror(fn ->
              Igniter.Code.Keyword.set_keyword_key(zipper, key, value_ast)
            end)

          case val do
            {:ok, updated} ->
              write_back(updated, path)

            :error ->
              {:error, "failed to add key #{inspect(key)} to project/0 in #{path}"}
          end
      end
    else
      {:error, reason} when is_binary(reason) -> {:error, reason}
      {:error, _} -> {:error, "could not read or parse #{path}"}
      :error -> {:error, "def project/0 not found in #{path}"}
    end
  end

  @doc """
  Adds a private function to the mix.exs module.

  The `body` parameter is the complete function definition as a string, e.g.:

      defp usage_rules do
        [file: "CLAUDE.md"]
      end

  Returns `{:ok, :updated}` if the function was added, `{:ok, :already_exists}`
  if a `defp` with the same name and arity already exists, or `{:error, reason}`
  on failure.

  ## Options

    * `:path` - path to the mix.exs file (default: `"mix.exs"`)
  """
  def add_defp(name, arity, body, opts \\ [])
      when is_atom(name) and is_integer(arity) and is_binary(body) do
    path = Keyword.get(opts, :path, "mix.exs") |> Path.expand()

    with {:ok, source} <- File.read(path),
         {:ok, zipper} <- parse_and_zip(source) do
      case Igniter.Code.Function.move_to_defp(zipper, name, arity) do
        {:ok, _} ->
          {:ok, :already_exists}

        :error ->
          result =
            with_clean_sourceror(fn ->
              append_to_module(zipper, body)
            end)

          case result do
            {:ok, updated} ->
              write_back(updated, path)

            :error ->
              {:error, "could not find defmodule block in #{path}"}
          end
      end
    else
      {:error, reason} when is_binary(reason) -> {:error, reason}
      {:error, _} -> {:error, "could not read or parse #{path}"}
    end
  end

  # Ensures Sourceror.to_string() (called internally by Igniter) can resolve
  # locals_without_parens without crashing. The crash happens because
  # Sourceror.locals_without_parens/0 calls Mix.Tasks.Format.formatter_for_file/2
  # which requires (a) a Mix project on the stack and (b) all formatter plugins
  # to be loadable. When running from a Mix.install script, neither is guaranteed.
  #
  # This function temporarily cds to a clean temp directory with a minimal
  # .formatter.exs (no plugins) and pushes a fallback Mix project if needed.
  defp with_clean_sourceror(fun) do
    needs_project = is_nil(Mix.Project.get())
    original_dir = File.cwd!()
    tmp_dir = Path.join(System.tmp_dir!(), "pro_gen_codegen")
    File.mkdir_p!(tmp_dir)
    File.write!(Path.join(tmp_dir, ".formatter.exs"), "[]\n")

    if needs_project do
      mod = Module.concat([__MODULE__, FallbackProject])

      unless Code.ensure_loaded?(mod) do
        Module.create(mod, quote do
          def project, do: [app: :pro_gen_codegen, version: "0.0.0", compilers: [], elixirc_paths: []]
        end, Macro.Env.location(__ENV__))
      end

      Mix.Project.push(mod)
    end

    File.cd!(tmp_dir)

    try do
      fun.()
    after
      File.cd!(original_dir)

      if needs_project do
        Mix.Project.pop()
      end
    end
  end

  defp parse_and_zip(source) do
    case Sourceror.parse_string(source) do
      {:ok, ast} -> {:ok, Sourceror.Zipper.zip(ast)}
      {:error, _} -> {:error, "failed to parse source"}
    end
  end

  defp write_back(zipper, path) do
    new_source =
      zipper
      |> Zipper.root()
      |> Sourceror.to_string(locals_without_parens: [])

    case File.write(path, new_source <> "\n") do
      :ok -> {:ok, :updated}
      {:error, reason} -> {:error, "failed to write #{path}: #{inspect(reason)}"}
    end
  end

  defp append_to_module(zipper, code) do
    case Igniter.Code.Common.move_to_do_block(zipper) do
      {:ok, body_zipper} ->
        updated =
          case body_zipper.node do
            {:__block__, _, _} ->
              body_zipper |> Zipper.down() |> Zipper.rightmost()

            _ ->
              body_zipper
          end
          |> Igniter.Code.Common.add_code(code, placement: :after)

        {:ok, updated}

      :error ->
        :error
    end
  end
end
