defmodule ProGen.Sys do
  @moduledoc """
  Low-level system command runner.

  Wraps `System.cmd/3` with stdout printing and `{:ok, output}` / `{:error, output}` returns.
  """

  def syscmd(cmd_string) when is_binary(cmd_string) do
    [cmd | args] = String.split(cmd_string)
    syscmd(cmd, args)
  end

  def syscmd(cmd, arg_list) do
    case System.cmd(cmd, arg_list, stderr_to_stdout: true) do
      {output, 0} ->
        IO.puts(output)
        {:ok, output}

      {error_output, code} ->
        IO.puts("Command failed (code #{code})")
        IO.puts(error_output)
        {:error, error_output}
    end
  end
end
