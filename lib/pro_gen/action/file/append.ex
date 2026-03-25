defmodule ProGen.Action.File.Append do
  @moduledoc """
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

  @impl true
  def perform(args) do
    # this operation is idempotent
    ProGen.Patch.File.append_line(args[:file], args[:line])
  end

  @impl true
  def confirm(_result, args) do
    file = args[:file]
    line = args[:line]

    case File.read(file) do
      {:ok, contents} ->
        if String.contains?(contents, line) do
          :ok
        else
          {:error, "line not found in #{file} after append"}
        end

      {:error, reason} ->
        {:error, "could not read #{file}: #{:file.format_error(reason)}"}
    end
  end

end
