defmodule ProGen.Sys do
  @moduledoc """
  Low-level system command runner.

  Streams command output to stdout in real time and returns `:ok` / `{:error, exit_code}`.
  """

  def syscmd(cmd_string) when is_binary(cmd_string) do
    [cmd | args] = String.split(cmd_string)
    syscmd(cmd, args)
  end

  def syscmd(cmd, arg_list) do
    case System.cmd(cmd, arg_list, stderr_to_stdout: true, into: IO.stream(:stdio, :line)) do
      {_, 0} ->
        :ok

      {_, code} ->
        IO.puts("Command failed (code #{code})")
        {:error, code}
    end
  end
end
