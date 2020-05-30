defmodule HukumEngineTest do
  use ExUnit.Case

  alias HukumEngine.Game
  alias HukumEngine.GameServer
  alias HukumEngine.Player

  test "HukumEngine.new_game creates a process and PID" do
    assert is_pid(HukumEngine.new_game)
  end

  test "adding teams" do
    pid = HukumEngine.new_game()
    assert HukumEngine.add_team(pid, ["player1", "player2"]) == :ok
    assert HukumEngine.add_team(pid, ["player3", "player4"]) == :ok
    assert HukumEngine.add_team(pid, ["player5", "player6"]) == :error
  end

  #test "Adding four players is :ok, fifth is :error" do
    #pid = HukumEngine.new_game()
    #assert HukumEngine.add_player(pid, "a") == :ok
    #assert HukumEngine.add_player(pid, "b") == :ok
    #assert HukumEngine.add_player(pid, "c") == :ok
    #assert HukumEngine.add_player(pid, "d") == :ok
    #assert HukumEngine.add_player(pid, "e") == :error
  #end

  #test "Once we have four players we can choose teams" do
    #pid = init_players()
    #assert HukumEngine.choose_team(pid, :player1, 1) == :ok
    #assert HukumEngine.choose_team(pid, :player2, 1) == :ok
    #assert HukumEngine.choose_team(pid, :player3, 2) == :ok
    #assert HukumEngine.choose_team(pid, :player4, 2) == :ok
  #end

  #test "Trying to join a team with 2 players returns :team_full" do
    #pid = init_players()
    #assert HukumEngine.choose_team(pid, :player1, 1) == :ok
    #assert HukumEngine.choose_team(pid, :player2, 1) == :ok
    #assert HukumEngine.choose_team(pid, :player3, 1) == {:error, :team_full}
    #assert HukumEngine.choose_team(pid, :player3, 2) == :ok
  #end

  #test "Player cannot join multiple teams" do
    #pid = init_players()
    #assert HukumEngine.choose_team(pid, :player1, 1) == :ok
    #assert HukumEngine.choose_team(pid, :player1, 2) == {:error, :already_assigned}
  #end

  #test "Filling the teams" do
    #pid = init_players()
    #HukumEngine.choose_team(pid, :player1, 1)
    #HukumEngine.choose_team(pid, :player2, 1)
    #HukumEngine.choose_team(pid, :player3, 2)
    #HukumEngine.choose_team(pid, :player4, 2)
  #end

  #test "starting the game" do
    #pid = init_players()
    #fill_teams(pid)
    #IO.inspect :sys.get_state(pid)
  #end

  #defp init_players() do
    #pid = HukumEngine.new_game()
    #HukumEngine.add_player(pid, "a")
    #HukumEngine.add_player(pid, "b")
    #HukumEngine.add_player(pid, "c")
    #HukumEngine.add_player(pid, "d")
    #pid
  #end

  #defp fill_teams(pid) do
    #HukumEngine.choose_team(pid, :player1, 1)
    #HukumEngine.choose_team(pid, :player2, 1)
    #HukumEngine.choose_team(pid, :player3, 2)
    #HukumEngine.choose_team(pid, :player4, 2)
  #end
end
