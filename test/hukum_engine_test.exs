defmodule HukumEngineTest do
  use ExUnit.Case
  import Kernel

  alias HukumEngine.{Deck, Game, GameServer, Player, Rules}

  test "HukumEngine.new_game creates a process and PID" do
    {:ok, pid} = HukumEngine.new_game("GAME1")
    assert is_pid(pid)
  end

  test "adding two teams is :ok, more throws an error" do
    HukumEngine.new_game("GAME2")
    assert HukumEngine.add_team(via("GAME2"), ["player1", "player2"]) == :ok
    assert HukumEngine.add_team(via("GAME2"), ["player3", "player4"]) == :ok
    assert HukumEngine.add_team(via("GAME2"), ["player5", "player6"]) == :error
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
    init_game("GAME3")
    game = HukumEngine.get_game_state(via("GAME3"))
    new_game = HukumEngine.call_or_pass(via("GAME3"), game.turn, :pass)
    assert new_game.turn == Game.next_player(game.turn)
  end

  test "four passes deals a new hand and restarts the call or pass process" do
    init_game("GAME4")
    g1 = HukumEngine.get_game_state(via("GAME4"))
    g2 = HukumEngine.call_or_pass(via("GAME4"), g1.turn, :pass)
    g3 = HukumEngine.call_or_pass(via("GAME4"), g2.turn, :pass)
    g4 = HukumEngine.call_or_pass(via("GAME4"), g3.turn, :pass)
    g5 = HukumEngine.call_or_pass(via("GAME4"), g4.turn, :pass)
    p1_g1_hand = Keyword.get(g1.players, :player_t1_p1).hand
    p1_g4_hand = Keyword.get(g4.players, :player_t1_p1).hand
    p1_g5_hand = Keyword.get(g5.players, :player_t1_p1).hand

    assert length(p1_g5_hand) == 4
    assert g1.turn == g5.turn
    assert p1_g1_hand == p1_g4_hand
    assert p1_g1_hand != p1_g5_hand
  end

  test "playing out of turn returns an error" do
    init_game("GAME5")
    g0 = HukumEngine.get_game_state(via("GAME5"))
    assert HukumEngine.call_or_pass(via("GAME5"), Game.next_player(g0.turn), :pass) == {:error, :not_your_turn}
    assert HukumEngine.call_or_pass(via("GAME5"), Game.next_player(g0.turn), :calling) == {:error, :not_your_turn}
  end

  test "announcing calling, playing first card, setting trump, dealing remaining cards" do
    init_game("GAME6")
    trump_to_call = :hearts
    g0 = HukumEngine.get_game_state(via("GAME6"))

    g1 = HukumEngine.call_or_pass(via("GAME6"), g0.turn, :pass)
    g2 = HukumEngine.call_or_pass(via("GAME6"), g1.turn, :calling)
    p1 = Keyword.get(g1.players, g2.turn)
    first_card = Enum.at(p1.hand, 0)
    g3 = HukumEngine.play_first_card(via("GAME6"), g2.turn, first_card)
    p2 = Keyword.get(g2.players, g1.turn)
    called = HukumEngine.call_trump(via("GAME6"), g3.turn, trump_to_call, p2.team)

    assert called.suit_trump == trump_to_call
    assert length(Keyword.get(called.players, g2.turn).hand) == 7
    assert length(Keyword.get(called.players, g3.turn).hand) == 8
    assert Enum.member?(called.current_trick, {g2.turn, first_card})
  end

  test "getting the highest card from a trick" do
    trump_trick = [
      {:player_t1_p1, %{rank: 7, suit: :diamonds}},
      {:player_t2_p1, %{rank: :ace, suit: :clubs}},
      {:player_t1_p2, %{rank: :king, suit: :clubs}},
      {:player_t2_p2, %{rank: 10, suit: :hearts}},
    ]
    trump_trick2 = [
      {:player_t1_p1, %{rank: 7, suit: :hearts}},
      {:player_t2_p1, %{rank: 9, suit: :hearts}},
      {:player_t1_p2, %{rank: :ace, suit: :spades}},
      {:player_t2_p2, %{rank: 10, suit: :hearts}},
    ]
    suit_trick = [
      {:player_t1_p1, %{rank: 7, suit: :diamonds}},
      {:player_t2_p1, %{rank: 8, suit: :diamonds}},
      {:player_t1_p2, %{rank: :king, suit: :diamonds}},
      {:player_t2_p2, %{rank: :ace, suit: :diamonds}},
    ]
    offsuit_trick = [
      {:player_t1_p1, %{rank: 7, suit: :diamonds}},
      {:player_t2_p1, %{rank: 8, suit: :clubs}},
      {:player_t1_p2, %{rank: :king, suit: :diamonds}},
      {:player_t2_p2, %{rank: :ace, suit: :diamonds}},
    ]

    assert Game.get_highest_card(trump_trick, :diamonds, :clubs) == Enum.at(trump_trick, 0)
    assert Game.get_highest_card(trump_trick2, :hearts, :spades) == Enum.at(trump_trick2, 3)
    assert Game.get_highest_card(suit_trick, :hearts, :diamonds) == Enum.at(suit_trick, 3)
    assert Game.get_highest_card(offsuit_trick, :hearts, :clubs) == Enum.at(offsuit_trick, 1)
  end

  # helpers
  # =====================================
  def via(id), do: GameServer.via_tuple(id)

  def init_game(game_id) do
    HukumEngine.new_game(game_id)
    HukumEngine.add_team(via(game_id), ["player1", "player2"])
    HukumEngine.add_team(via(game_id), ["player3", "player4"])
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
