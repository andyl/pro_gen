defmodule ProGen.CodeMods.File do

  def append_line(_file, _line) do
    # check to ensure the file exists
    # append the line to the file
    # idempotently
    # if the contents are changed, update the file
    :ok
  end

  def sed_file(file, expression) do
    # check to ensure the file exists
    "sed -i '#{expression}' #{file}"
    |> ProGen.Sys.cmd()
    :ok
  end

end
