defmodule HukumEngineTest do
  use ExUnit.Case

  alias HukumEngine.Game
  alias HukumEngine.GameServer
  alias HukumEngine.Player

  @test_player_name "vijay"

  test "HukumEngine.new_game creates a process and PID" do
    assert is_pid(HukumEngine.new_game)
  end

  test "HukumEngine FSM starts in `waiting_for_players` state" do
    pid = HukumEngine.new_game
    fsm_pid = :sys.get_state(pid).fsm
    { fsm_state, _ } = :sys.get_state(fsm_pid)
    assert fsm_state == :waiting_for_players
  end

  test "Adding four players is :ok, fifth is :error" do
    pid = HukumEngine.new_game()
    assert HukumEngine.add_player(pid, "a") == :ok
    assert HukumEngine.add_player(pid, "b") == :ok
    assert HukumEngine.add_player(pid, "c") == :ok
    assert HukumEngine.add_player(pid, "d") == :ok
    assert HukumEngine.add_player(pid, "e") == :error
  end
end
