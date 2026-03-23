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
end
