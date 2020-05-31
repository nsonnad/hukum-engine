defmodule HukumEngineTest do
  use ExUnit.Case
  import Kernel

  alias HukumEngine.{Deck, Game, GameServer, Player, Rules}

  test "HukumEngine.new_game creates a process and PID" do
    assert is_pid(HukumEngine.new_game)
  end

  test "adding two teams is :ok, more throws an error" do
    pid = HukumEngine.new_game()
    assert HukumEngine.add_team(pid, ["player1", "player2"]) == :ok
    assert HukumEngine.add_team(pid, ["player3", "player4"]) == :ok
    assert HukumEngine.add_team(pid, ["player5", "player6"]) == :error
  end

  test "start_new_hand deals each player four cards" do
    game =
      %Game{
        rules: %Rules{stage: :call_or_pass},
        players: test_players(),
        dealer: :player_t1_p1
      } |> Game.start_new_hand
    assert Enum.all?(game.players, fn {_, p} -> length(p.hand) == 4 end)
  end

  test "distribute_cards deals cards clockwise from dealer" do
    deck = elem(Enum.split(Deck.shuffled(), 16), 0)
    dealer = :player_t1_p1
    players = Game.distribute_cards(test_players(), Game.next_player(dealer), deck)

    assert Enum.at(Keyword.get(players, :player_t2_p1).hand, 3) == Enum.at(deck, 0)
    assert Enum.at(Keyword.get(players, :player_t1_p2).hand, 3) == Enum.at(deck, 1)
    assert Enum.at(Keyword.get(players, :player_t2_p2).hand, 3) == Enum.at(deck, 2)
    assert Enum.at(Keyword.get(players, :player_t1_p1).hand, 3) == Enum.at(deck, 3)
  end

  test "passing advances the turn to the next player" do
    pid = init_game()
    game = HukumEngine.get_game_state(pid)
    new_game = HukumEngine.pass(pid)
    assert new_game.turn == Game.next_player(game.turn)
  end

  test "four passes deals a new hand and restarts the call or pass process" do
    pid = init_game()
    g1 = HukumEngine.get_game_state(pid)
    g2 = HukumEngine.pass(pid)
    g3 = HukumEngine.pass(pid)
    g4 = HukumEngine.pass(pid)
    g5 = HukumEngine.pass(pid)
    p1_g1_hand = Keyword.get(g1.players, :player_t1_p1).hand
    p1_g4_hand = Keyword.get(g4.players, :player_t1_p1).hand
    p1_g5_hand = Keyword.get(g5.players, :player_t1_p1).hand

    assert length(p1_g5_hand) == 4
    assert g1.turn == g5.turn
    assert p1_g1_hand == p1_g4_hand
    assert p1_g1_hand != p1_g5_hand
  end

  test "announcing calling, playing first card, setting trump" do
    pid = init_game()
    first_card = %{rank: :ace, suit: :spades}
    trump_to_call = :hearts

    HukumEngine.pass(pid)
    g1 = HukumEngine.calling(pid)
    p1 = Keyword.get(g1.players, g1.turn)
    g2 = HukumEngine.play_first_card(pid, g1.turn, p1.team, first_card)
    p2 = Keyword.get(g2.players, g2.turn)
    called = HukumEngine.call_trump(pid, trump_to_call, p2.team)

    assert called.suit_trump == trump_to_call
    assert Enum.member?(called.current_trick, {g1.turn, p1.team, first_card})
  end

  test "getting the highest card from a trick" do
    trump_trick = [
      {:player_t1_p1, 1, %{rank: 7, suit: :diamonds}},
      {:player_t2_p1, 2, %{rank: :ace, suit: :clubs}},
      {:player_t1_p2, 1, %{rank: :king, suit: :clubs}},
      {:player_t2_p2, 2, %{rank: 10, suit: :hearts}},
    ]
    trump_trick2 = [
      {:player_t1_p1, 1, %{rank: 7, suit: :hearts}},
      {:player_t2_p1, 2, %{rank: 9, suit: :hearts}},
      {:player_t1_p2, 1, %{rank: :ace, suit: :spades}},
      {:player_t2_p2, 2, %{rank: 10, suit: :hearts}},
    ]
    suit_trick = [
      {:player_t1_p1, 1, %{rank: 7, suit: :diamonds}},
      {:player_t2_p1, 2, %{rank: 8, suit: :diamonds}},
      {:player_t1_p2, 1, %{rank: :king, suit: :diamonds}},
      {:player_t2_p2, 2, %{rank: :ace, suit: :diamonds}},
    ]
    offsuit_trick = [
      {:player_t1_p1, 1, %{rank: 7, suit: :diamonds}},
      {:player_t2_p1, 2, %{rank: 8, suit: :clubs}},
      {:player_t1_p2, 1, %{rank: :king, suit: :diamonds}},
      {:player_t2_p2, 2, %{rank: :ace, suit: :diamonds}},
    ]

    assert Game.get_highest_card(trump_trick, :diamonds, :clubs) == Enum.at(trump_trick, 0)
    assert Game.get_highest_card(trump_trick2, :hearts, :spades) == Enum.at(trump_trick2, 3)
    assert Game.get_highest_card(suit_trick, :hearts, :diamonds) == Enum.at(suit_trick, 3)
    assert Game.get_highest_card(offsuit_trick, :hearts, :clubs) == Enum.at(offsuit_trick, 1)
  end

  # helpers
  # =====================================


  defp init_game() do
    pid = HukumEngine.new_game()
    HukumEngine.add_team(pid, ["player1", "player2"])
    HukumEngine.add_team(pid, ["player3", "player4"])
    pid
  end

  defp test_players() do
    [
      player_t1_p1: %Player{name: "p1"},
      player_t2_p1: %Player{name: "p2"},
      player_t1_p2: %Player{name: "p3"},
      player_t2_p2: %Player{name: "p4"},
    ]
  end
end
