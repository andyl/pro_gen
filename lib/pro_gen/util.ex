defmodule ProGen.Util do
  @moduledoc false

  @doc false
  def unk_term_error(type, term, list) do
    s1 = "Unknown #{type} #{inspect(term)}\n"
    s2 = "< Valid Terms >\n"
    s3 = to_table(list)
    s1 <> s2 <> s3
  end

  defp to_table(list) do
    max_width =
      list |> Enum.map(fn {first, _} -> String.length(first) end) |> Enum.max(fn -> 0 end)

    Enum.map_join(list, "\n", fn {first, second} ->
      String.pad_trailing(first, max_width) <> " - " <> second
    end)
  end

  @doc false
  def compress(string) do
    String.replace(string, ~r/ +/, " ")
  end

  @doc false
  def to_snake(str) when is_binary(str) do
    str
    |> String.replace(~r/([A-Z])/, "_\\1")
    |> String.replace(~r/[- ]/, "_")
    |> String.replace(~r/_+/, "_")
    |> String.trim_leading("_")
    |> String.downcase()
  end

  @doc false
  def to_pascal(str) when is_binary(str) do
    str
    |> String.replace(~r/[_-\s]+/, " ")
    |> String.split()
    |> Enum.map_join(&String.capitalize/1)
  end
end
