defmodule ProGenTest do
  use ExUnit.Case, async: true
  doctest ProGen

  test "greets the world" do
    assert ProGen.hello() == :world
  end
end
