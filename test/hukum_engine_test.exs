defmodule HukumEngineTest do
  use ExUnit.Case

  alias HukumEngine.Game
  alias HukumEngine.Player

  @test_player_name "vijay"

  test "HukumEngine.new_game creates a process and PID" do
    assert is_pid(HukumEngine.new_game)
  end

  test "HukumEngine.new_game initializes game in :waiting_for_players stage" do
    game = Game.new_game()
    assert game.stage == :waiting_for_players
  end

  test "Game.put_player initializes a player and adds to the players list" do
    game = Game.new_game()
    game = Game.put_player(game, @test_player_name)
    assert MapSet.member?(game.players, %Player{ name: @test_player_name, hand: []})
  end

  test "Game.put_player returns an error if the username is already taken" do

  end

  test "Game.put_player does not add a player if already 4 players" do
    game = Game.new_game()
           |> Game.put_player("a")
           |> Game.put_player("b")
           |> Game.put_player("c")
           |> Game.put_player("d")
           |> Game.put_player("e")
           |> Game.put_player("f")
           |> Game.put_player("g")

    assert MapSet.size(game.players) == 4
  end
end
