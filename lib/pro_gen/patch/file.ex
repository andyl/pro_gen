defmodule ProGen.Patch.File do
  @moduledoc """
  File-level code modifications: appending lines, appending blocks, replacing
  strings, and running sed expressions.

  All append operations are idempotent — they no-op if the content already
    exists in the file.
  """

  @doc """
  Appends a single line to the end of `file` unless it already appears in the
  file.

  Ensures the file ends with a newline before appending. Returns `:ok` on
  success (including when the line already exists), or `{:error, reason}`
  if the file cannot be read.
  """
  def append_line(file, line) do
    with {:ok, contents} <- Elixir.File.read(file) do
      if String.contains?(contents, line) do
        :ok
      else
        trailing = if String.ends_with?(contents, "\n"), do: "", else: "\n"
        Elixir.File.write(file, contents <> trailing <> line <> "\n")
      end
    end
  end

  @doc """
  Appends a multi-line block of text to the end of `file` unless it already
  appears in the file.

  The block is compared against the file contents after trimming trailing
  whitespace from both, so minor trailing-whitespace differences don't cause
  duplicate appends. Ensures the file ends with a newline before appending.
  Returns `:ok` on success (including when the block already exists), or
  `{:error, reason}` if the file cannot be read.
  """
  def append_block(file, block) do
    with {:ok, contents} <- Elixir.File.read(file) do
      if String.contains?(String.trim_trailing(contents), String.trim_trailing(block)) do
        :ok
      else
        trailing = if String.ends_with?(contents, "\n"), do: "", else: "\n"
        Elixir.File.write(file, contents <> trailing <> String.trim_trailing(block) <> "\n")
      end
    end
  end

  @doc """
  Replaces all occurrences of `old_string` with `new_string` in `file`.

  Writes the file only if the content actually changed. Returns `:ok` on
  success (including when `old_string` is not found), or `{:error, reason}`
  if the file cannot be read.
  """
  def replace(file, old_string, new_string) do
    with {:ok, contents} <- Elixir.File.read(file) do
      replaced = String.replace(contents, old_string, new_string)

      if replaced == contents do
        :ok
      else
        Elixir.File.write(file, replaced)
      end
    end
  end

  @doc """
  Runs a sed in-place substitution on `file`.

  The `expression` is passed directly to `sed -i`, e.g. `"s/foo/bar/g"`.
  Returns `:ok` on success, `{:error, exit_code}` if sed fails,
  or `{:error, :enoent}` if the file does not exist.
  """
  def sed_file(file, expression) do
    if Elixir.File.exists?(file) do
      case System.cmd("sed", ["-i", expression, file], stderr_to_stdout: true) do
        {_, 0} -> :ok
        {_, code} -> {:error, code}
      end
    else
      {:error, :enoent}
    end
  end
end
