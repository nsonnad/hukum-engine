defmodule HukumEngineTest do
  use ExUnit.Case
  import Kernel

  alias HukumEngine.{Deck, Game, GameServer, Player, Rules}

  test "HukumEngine.new_game creates a process and PID" do
    {:ok, pid} = HukumEngine.new_game("GAME1")
    assert is_pid(pid)
  end

  test "adding and removing players" do
    HukumEngine.new_game("GAME2")
    assert HukumEngine.add_player(via("GAME2"), :player1) == :ok
    assert HukumEngine.add_player(via("GAME2"), :player2) == :ok
    assert HukumEngine.remove_player(via("GAME2"), :player1) == :ok
    assert HukumEngine.remove_player(via("GAME2"), :player2) == :ok

    assert HukumEngine.add_player(via("GAME2"), :player1) == :ok
    assert HukumEngine.add_player(via("GAME2"), :player2) == :ok
    assert HukumEngine.add_player(via("GAME2"), :player3) == :ok

    assert HukumEngine.remove_player(via("GAME2"), :player3) == :ok
    assert HukumEngine.add_player(via("GAME2"), :player3) == :ok

    assert HukumEngine.add_player(via("GAME2"), :player4) == :ok
    assert HukumEngine.add_player(via("GAME2"), :player5) == :error
  end

  test "choosing and confirming teams" do
    HukumEngine.new_game("GAME4")
    HukumEngine.add_player(via("GAME4"), :player1)
    HukumEngine.add_player(via("GAME4"), :player2)
    HukumEngine.add_player(via("GAME4"), :player3)
    HukumEngine.add_player(via("GAME4"), :player4)

    assert HukumEngine.choose_team(via("GAME4"), :player1, 1) == {:ok, %{team_counts: [1, 0]}}
    assert HukumEngine.choose_team(via("GAME4"), :player2, 1) == {:ok, %{team_counts: [2, 0]}}
    assert HukumEngine.choose_team(via("GAME4"), :player3, 1) == { :error, :team_full }
    assert HukumEngine.choose_team(via("GAME4"), :player3, 2) == {:ok, %{team_counts: [2, 1]}}
    assert HukumEngine.confirm_teams(via("GAME4")) == { :error, :teams_not_filled }
    assert HukumEngine.choose_team(via("GAME4"), :player4, 2) == {:ok, %{team_counts: [2, 2]}}

    {:ok, confirmed} = HukumEngine.confirm_teams(via("GAME4"))
    assert confirmed.stage == :call_or_pass
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
    players = Game.distribute_cards(test_players(), Game.next_player(test_players(), dealer), deck)

    assert Enum.at(Keyword.get(players, :player_t2_p1).hand, 3) == Enum.at(deck, 0)
    assert Enum.at(Keyword.get(players, :player_t1_p2).hand, 3) == Enum.at(deck, 1)
    assert Enum.at(Keyword.get(players, :player_t2_p2).hand, 3) == Enum.at(deck, 2)
    assert Enum.at(Keyword.get(players, :player_t1_p1).hand, 3) == Enum.at(deck, 3)
  end

  test "once teams are confirmed, players are sorted in the right order" do
    init_game("GAME5")
    {:ok, game} = HukumEngine.get_game_state(via("GAME5"))
    assert Keyword.keys(game.players) == [:player1, :player3, :player2, :player4]
  end

  test "passing advances the turn to the next player" do
    init_game("GAME6")
    {:ok, game} = HukumEngine.get_game_state(via("GAME6"))
    {:ok, new_game} = HukumEngine.call_or_pass(via("GAME6"), game.turn, :pass)
    assert new_game.turn == Game.next_player(game.players, game.turn)
  end

  test "four passes deals a new hand and restarts the call or pass process" do
    init_game("GAME7")
    {:ok, g1} = HukumEngine.get_game_state(via("GAME7"))
    {:ok, g2} = HukumEngine.call_or_pass(via("GAME7"), g1.turn, :pass)
    {:ok, g3} = HukumEngine.call_or_pass(via("GAME7"), g2.turn, :pass)
    {:ok, g4} = HukumEngine.call_or_pass(via("GAME7"), g3.turn, :pass)
    {:ok, g5} = HukumEngine.call_or_pass(via("GAME7"), g4.turn, :pass)
    p1_g1_hand = Keyword.get(g1.players, :player1).hand
    p1_g4_hand = Keyword.get(g4.players, :player1).hand
    p1_g5_hand = Keyword.get(g5.players, :player1).hand

    assert length(p1_g5_hand) == 4
    assert g1.turn == g5.turn
    assert p1_g1_hand == p1_g4_hand
    assert p1_g1_hand != p1_g5_hand
  end

  test "playing out of turn returns an error" do
    init_game("GAME8")
    {:ok, g0} = HukumEngine.get_game_state(via("GAME8"))
    assert HukumEngine.call_or_pass(via("GAME8"), Game.next_player(g0.players, g0.turn), :pass) == {:error, :not_your_turn}
    assert HukumEngine.call_or_pass(via("GAME8"), Game.next_player(g0.players, g0.turn), :calling) == {:error, :not_your_turn}
  end

  test "announcing calling, playing first card, setting trump, dealing remaining cards" do
    init_game("GAME9")
    trump_to_call = :hearts
    {:ok, g0} = HukumEngine.get_game_state(via("GAME9"))

    {:ok, g1} = HukumEngine.call_or_pass(via("GAME9"), g0.turn, :pass)
    {:ok, g2} = HukumEngine.call_or_pass(via("GAME9"), g1.turn, :calling)
    p1 = Keyword.get(g1.players, g2.turn)
    first_card = Enum.at(p1.hand, 0)
    {:ok, g3} = HukumEngine.play_card(via("GAME9"), g2.turn, first_card)
    p2 = Keyword.get(g2.players, g1.turn)
    {:ok, called} = HukumEngine.call_trump(via("GAME9"), g3.turn, trump_to_call)

    assert called.suit_trump == trump_to_call
    assert length(Keyword.get(called.players, g2.turn).hand) == 7
    assert length(Keyword.get(called.players, g3.turn).hand) == 8
    assert Enum.member?(called.current_trick, Map.put(first_card, :player, g2.turn))
  end

  test "getting the highest card from a trick" do
    trump_trick = [
      %{player: "player_t1_p1", rank: :seven, suit: :diamonds},
      %{player: "player_t2_p1", rank: :ace, suit: :clubs},
      %{player: "player_t1_p2", rank: :king, suit: :clubs},
      %{player: "player_t2_p2", rank: :ten, suit: :hearts},
    ]
    trump_trick2 = [
      %{player: "player_t1_p1", rank: :seven, suit: :hearts},
      %{player: "player_t2_p1", rank: :nine, suit: :hearts},
      %{player: "player_t1_p2", rank: :ace, suit: :spades},
      %{player: "player_t2_p2", rank: :ten, suit: :hearts},
    ]
    suit_trick = [
      %{player: "player_t1_p1", rank: :seven, suit: :diamonds},
      %{player: "player_t2_p1", rank: :eight, suit: :diamonds},
      %{player: "player_t1_p2", rank: :king, suit: :diamonds},
      %{player: "player_t2_p2", rank: :ace, suit: :diamonds},
    ]
    offsuit_trick = [
      %{player: "player_t1_p1", rank: :seven, suit: :diamonds},
      %{player: "player_t2_p1", rank: :eight, suit: :clubs},
      %{player: "player_t1_p2", rank: :king, suit: :diamonds},
      %{player: "player_t2_p2", rank: :ace, suit: :diamonds},
    ]

    assert Game.get_highest_card(trump_trick, :diamonds, :clubs) == Enum.at(trump_trick, 0)
    assert Game.get_highest_card(trump_trick2, :hearts, :spades) == Enum.at(trump_trick2, 3)
    assert Game.get_highest_card(suit_trick, :hearts, :diamonds) == Enum.at(suit_trick, 3)
    assert Game.get_highest_card(offsuit_trick, :hearts, :clubs) == Enum.at(offsuit_trick, 1)
  end

  test "sorting hands" do
    game = %Game{
      players: [
        {:player1, %{hand:
          [
            %{rank: :seven, suit: :hearts},
            %{rank: :ten, suit: :spades},
            %{rank: :seven, suit: :diamonds},
            %{rank: :ace, suit: :clubs}
          ]}
        },
        {:player12, %{hand:
          [
            %{rank: :king, suit: :spades},
            %{rank: :jack, suit: :spades},
            %{rank: :queen, suit: :spades},
            %{rank: :seven, suit: :hearts}
          ]}
        }
      ]
    }

    expected_result = [
      player1: %{
        hand: [
          %{rank: :ace, suit: :clubs},
          %{rank: :seven, suit: :diamonds},
          %{rank: :ten, suit: :spades},
          %{rank: :seven, suit: :hearts}
        ]
      },
      player12: %{
        hand: [
          %{rank: :jack, suit: :spades},
          %{rank: :queen, suit: :spades},
          %{rank: :king, suit: :spades},
          %{rank: :seven, suit: :hearts}
        ]
      }
    ]

    assert Game.sort_hands(game).players == expected_result
  end

  # helpers
  # =====================================
  def via(id), do: GameServer.via_tuple(id)

  def init_game(game_id) do
    HukumEngine.new_game(game_id)
    HukumEngine.add_player(via(game_id), :player1)
    HukumEngine.add_player(via(game_id), :player2)
    HukumEngine.add_player(via(game_id), :player3)
    HukumEngine.add_player(via(game_id), :player4)

    HukumEngine.choose_team(via(game_id), :player1, 1)
    HukumEngine.choose_team(via(game_id), :player2, 1)
    HukumEngine.choose_team(via(game_id), :player3, 2)
    HukumEngine.choose_team(via(game_id), :player4, 2)

    HukumEngine.confirm_teams(via(game_id))
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
