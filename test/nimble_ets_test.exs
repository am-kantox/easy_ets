defmodule NimbleETSTest do
  use ExUnit.Case
  doctest NimbleETS

  test "greets the world" do
    assert NimbleETS.hello() == :world
  end
end
