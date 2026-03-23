defmodule ProGen.Action.File.Append do
  @moduledoc """
  Use igniter to install a dependency in your mix.exs file.
  Append a line to a file, idempotently.
  """

  use ProGen.Action

  @impl true
  def opts_def do
    [
      file: [type: :string, required: true, doc: "Target file"],
      line: [type: :string, required: true, doc: "Line to append"],
    ]
  end

  @impl true
  def validate(args), do: [{"filesys", [{:has_file, args[:file]}]}]

  # @impl true
  # def depends_on(_args), do: [{"archive.install", package: "igniter_new"}]

  # @impl true
  # def needed?(args) do
  #   deps = parse_deps(args)
  #   Enum.any?(deps, fn dep -> not dep_installed?(dep) end)
  # end

  @impl true
  def perform(args) do
    # this operation is idempotent
    ProGen.CodeMods.File.append_line(args[:file], args[:line])
  end

  @impl true
  def confirm(_result, args) do
    _file = args[:file]
    _line = args[:line]
    # confirm that the append operation has succeeded
    # do this with grep or some sort of string-matching function
  end

end
