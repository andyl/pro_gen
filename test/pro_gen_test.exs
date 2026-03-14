defmodule ProGenTest do
  use ExUnit.Case
  doctest ProGen

  test "greets the world" do
    assert ProGen.hello() == :world
  end
end
