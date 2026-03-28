defmodule ProGen.Xt.PGIO do
  @moduledoc """
  Formatted console output helpers (puts, inspect, err, log).
  """

  @doc """
  Prints a formatted message prefixed with `>`.
  """
  def puts(text) do
    text
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.each(fn line ->
      output = IO.ANSI.color(208) <> line <> IO.ANSI.reset()
      IO.puts("> #{output}")
    end)
  end

  @doc """
  Inspect an elixir term.
  """
  def inspect(text, term, _opts \\ []) do
    puts(text)
    IO.inspect(term)
  end

  @doc """
  Prints an error message.
  """
  def err(text) when is_binary(text), do: err_puts(text)
  def err(term), do: term |> inspect() |> err_puts()

  def err_puts(text) do
    output = IO.ANSI.light_red() <> text <> IO.ANSI.reset()
    IO.puts("Error: #{output}")
  end

  @doc """
  Logs an info-level message via `Logger`.
  """
  def log(text) do
    require Logger
    Logger.info(IO.ANSI.light_yellow() <> text <> IO.ANSI.reset())
    Logger.flush()
  end

  @doc """
  Clears the terminal screen.
  """
  def clear do
    IO.write(IO.ANSI.clear() <> IO.ANSI.home())
  end
end
