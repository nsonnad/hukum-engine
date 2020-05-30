defmodule HukumEngineTest do
  use ExUnit.Case

  alias HukumEngine.Game
  alias HukumEngine.GameServer
  alias HukumEngine.Player

  test "HukumEngine.new_game creates a process and PID" do
    assert is_pid(HukumEngine.new_game)
  end

  test "adding two teams is :ok, more throws an error" do
    pid = HukumEngine.new_game()
    assert HukumEngine.add_team(pid, ["player1", "player2"]) == :ok
    assert HukumEngine.add_team(pid, ["player3", "player4"]) == :ok
    assert HukumEngine.add_team(pid, ["player5", "player6"]) == :error
  end
end
