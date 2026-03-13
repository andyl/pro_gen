defmodule ProGen.Script do
  @moduledoc """
  Functions for ProGen scripts.

    * `put_schema/1` — Store an Optimus schema in ProGen.Env
    * `get_schema/0`  — Retrieve the stored Optimus schema
    * `parse_args/2`  — Parse argv against an Optimus schema
    * `parse_args/1`  — Parse argv using the stored schema
    * `parse_args/0`  — Parse System.argv() using the stored schema
    * `usage/1`       — Generate help text from an Optimus schema
    * `usage/0`       — Generate help text from the stored schema
    * `msg/1`         — Print a formatted message
    * `cmd/2`         — Print description then run a system command
    * `op/3`          — Run a ProGen operation (stub)
    * `git/1`         — Run a git command
    * `commit/1`      — Stage all and commit

  Usage Example:

  ```
  #!/usr/bin/env elixir

  Mix.install([:pro_gen, github: "andyl/pro_gen"])

  alias ProGen.Script, as: PG

  PG.msg "Hello World"
  ...
  """

  # --- Schema storage ---

  @doc """
  Stores an Optimus schema in `ProGen.Env` under `:pg_arg_schema`.
  """
  def put_schema(schema) do
    ProGen.Env.put(:pg_arg_schema, schema)
  end

  @doc """
  Retrieves the Optimus schema previously stored by `put_schema/1`.
  """
  def get_schema do
    ProGen.Env.get(:pg_arg_schema)
  end

  # --- CLI parsing ---

  @doc """
  Parses `argv` (list or string) against an explicit Optimus `schema`.

  Returns `{:ok, %Optimus.ParseResult{}}`, `{:error, errors}`, `:help`, or `:version`.
  """
  def parse_args(schema, argv) when is_binary(argv),
    do: parse_args(schema, String.split(argv))

  def parse_args(schema, argv) when is_list(argv) do
    optimus = Optimus.new!(schema)
    Optimus.parse(optimus, argv)
  end

  @doc """
  Parses `argv` using the schema stored by `put_schema/1`.

  On success, merges `parsed.args`, `parsed.options`, and `parsed.flags` into
  a single flat map and stores it in `ProGen.Env` under `:pg_args`.

  Returns `{:ok, merged_map}`, `{:error, errors}`, `:help`, or `:version`.
  On `:help`, auto-prints usage. On `:version`, auto-prints the version string.
  """
  def parse_args(argv) when is_list(argv) or is_binary(argv) do
    schema = get_schema()

    case parse_args(schema, argv) do
      {:ok, parsed} ->
        merged = Map.merge(parsed.args, Map.merge(parsed.options, parsed.flags))
        ProGen.Env.put(:pg_args, merged)
        {:ok, merged}

      :help ->
        usage() |> IO.puts()
        :help

      :version ->
        IO.puts(schema[:version] || "unknown")
        :version

      {:error, errors} ->
        errors
        |> List.wrap()
        |> Enum.each(&IO.puts(:stderr, &1))

        usage() |> IO.puts()
        do_halt(1)
    end
  end

  @doc """
  Parses `System.argv()` using the stored schema. Convenience for `parse_args(System.argv())`.
  """
  def parse_args do
    parse_args(System.argv())
  end

  @doc """
  Generates help text from an explicit Optimus `schema`.
  """
  def usage(schema) when is_list(schema) do
    optimus = Optimus.new!(schema)
    Optimus.help(optimus)
  end

  @doc """
  Generates help text from the schema stored by `put_schema/1`.
  """
  def usage do
    usage(get_schema())
  end

  # --- DSL functions ---

  @doc """
  Prints a formatted description, then runs a system command via `ProGen.Sys.syscmd/1`.
  """
  def cmd(desc, command) do
    msg(desc)
    ProGen.Sys.syscmd(command)
  end

  @doc """
  Runs a ProGen operation. Currently a stub.
  """
  def op(_desc, _operation, _opts \\ []) do
    IO.puts("Under Construction")
  end

  @doc """
  Prints a formatted message prefixed with `>>>>>`.
  """
  def msg(text) do
    IO.puts(">>>>> #{text}")
  end

  @doc """
  Stages all files and commits with the given message.
  """
  def commit(message) do
    git("add .")
    git("commit -am \"#{message}\"")
  end

  @doc """
  Runs a git command. Accepts a string (split on spaces) or a list of args.
  """
  def git(arg_string) when is_binary(arg_string),
    do: arg_string |> String.split(" ") |> git()

  def git(arg_list) when is_list(arg_list),
    do: ProGen.Sys.syscmd("git", arg_list)

  # --- Private helpers ---

  defp do_halt(code) do
    halt_fn = Application.get_env(:pro_gen, :system_halt, &System.halt/1)
    halt_fn.(code)
  end
end
