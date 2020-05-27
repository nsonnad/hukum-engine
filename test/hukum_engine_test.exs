defmodule HukumEngineTest do
  use ExUnit.Case
  doctest HukumEngine

  test "greets the world" do
    assert HukumEngine.hello() == :world
  end
end
