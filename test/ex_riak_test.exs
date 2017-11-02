defmodule ExRiakTest do
  use ExUnit.Case
  doctest ExRiak

  test "greets the world" do
    assert ExRiak.hello() == :world
  end
end
