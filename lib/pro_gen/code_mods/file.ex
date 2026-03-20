defmodule ProGen.CodeMods.File do

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

  def sed_file(file, expression) do
    if Elixir.File.exists?(file) do
      "sed -i '#{expression}' #{file}"
      |> ProGen.Sys.cmd()
    else
      {:error, :enoent}
    end
  end

end
