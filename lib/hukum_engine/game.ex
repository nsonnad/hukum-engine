defmodule HukumEngine.Game do
  alias HukumEngine.{Deck, Game, Player, Rules}
  import Kernel

  @deck_size 32

  defstruct(
    id: nil,
    players: [],
    score: %{ 1 => 0, 2 => 0},
    rules: :none,
    dealer: nil,
    deck: nil,
    turn: nil,
    calling_team: nil,
    current_trick: [],
    hand_trick_winners: [],
    suit_led: :undecided,
    suit_trump: :undecided
  )

  # API-level
  # ===============================

  def new_game(game_id, rules, players \\ []) do
    %Game{ id: game_id, rules: rules, players: players }
  end

  # add first team
  def add_team(game = %Game{rules: %Rules{team_status: {:empty, :empty}}}, player_names) do
    team_players = player_names |> Enum.with_index |> Enum.map(&create_player(&1, 1))
    %{game | players: team_players }
  end

  # add second team
  def add_team(game = %Game{rules: %Rules{team_status: {:filled, :empty}}}, player_names) do
    team_players = player_names |> Enum.with_index |> Enum.map(&create_player(&1, 2))

    # arrange players by seat order
    [p1, p2, p3, p4] = game.players ++ team_players
    players = [p1, p3, p2, p4]

    %{game | players: players, dealer: random_player(players) }
    |> start_new_hand
  end

  def create_player({ name, index }, team_number) do
    player_id = String.to_atom("player_t#{team_number}_p#{index+1}")
    { player_id, %Player{name: name, team: team_number }}
  end

  def start_new_hand(game) do
    deck = Enum.split(Deck.shuffled(), div(@deck_size, 2))
    turn = next_player(game.dealer)
    players =
      game.players
      |> clear_hands
      |> distribute_cards(turn, elem(deck, 0))

    %{ game |
      players: players,
      hand_trick_winners: [],
      suit_led: :undecided,
      deck: elem(deck, 1),
      turn: turn }
  end

  def play_card(game, player_id, card) do
    current_trick = [ {player_id, card} | game.current_trick ]
    {_, players} = remove_card_from_hand(game.players, player_id, card)
    %{game | players: players, current_trick: current_trick }
  end

  def check_trick(game) do
    case length(game.current_trick) do
      4 -> {:ok, game |> finish_trick}
      1 ->
        {_, card_led} = Enum.at(game.current_trick, 0)
        {:ok, set_suit_led(game, card_led.suit) |> next_turn}
      _ -> {:ok, game |> next_turn}
    end
  end

  def check_hand(game) do
    case length(game.hand_trick_winners) == 8 do
      true ->
        winning_team = hand_winning_team(game.hand_trick_winners, game.calling_team)
        new_score = Map.get(game.score, winning_team) + points_to_add(winning_team, game.calling_team)
        game = %{game |
          score: Map.put(game.score, winning_team, new_score),
          suit_led: :undecided
        } |> start_new_hand

        {:ok, game}

      false ->
        {:ok, game}
    end
  end

  # helpers
  # ===============================
  def set_suit_led(game, suit), do: %{game | suit_led: suit}

  def points_to_add(winning_team, calling_team) when winning_team == calling_team, do: 1
  def points_to_add(winning_team, calling_team) when winning_team != calling_team, do: 2

  def hand_winning_team(hand_trick_winners, calling_team) do
    case length(Enum.filter(hand_trick_winners, fn t -> t == calling_team end)) do
      count when count >= 5 -> calling_team
      _ -> other_team(calling_team)
    end
  end

  def finish_trick(game) do
    {hi_player, _hi_card} = get_highest_card(game.current_trick, game.suit_trump, game.suit_led)
    hi_team = get_player_team(game.players, hi_player)
    %{game |
      turn: hi_player,
      suit_led: :undecided,
      hand_trick_winners: [ hi_team | game.hand_trick_winners ],
      current_trick: []
    }
  end

  def remove_card_from_hand(players, player_id, card) do
    Keyword.get_and_update(players, player_id, fn player ->
      { player, Map.put(player, :hand, List.delete(player.hand, card))}
    end)
  end

  def get_highest_card(trick, trump, suit_led) do
    Enum.max_by(trick, fn {_player, card} ->
      score_card(card.rank, card.suit, trump, suit_led)
    end)
  end

  defp get_player_team(players, player) do
    Keyword.get(players, player).team
  end

  def score_card(rank, card_suit, trump, _led_suit) when card_suit == trump do
    Deck.value(rank) + 8
  end

  def score_card(rank, card_suit, _trump, led_suit) when card_suit == led_suit do
    Deck.value(rank)
  end

  def score_card(_rank, _card_suit, _trump, _led_suit), do: 0

  def set_trump(game, trump, team) do
    %{ game | suit_trump: trump, calling_team: team }
  end

  def game_state_reply(game) do
    %{
      id: game.id,
      stage: game.rules.stage,
      players: game.players,
      turn: game.turn,
      score: game.score,
      current_trick: game.current_trick,
      suit_trump: game.suit_trump,
      suit_led: game.suit_led,
      calling_team: game.calling_team
    }
  end

  def deal_second_set(game) do
    %{game | players: distribute_cards(game.players, game.turn, game.deck)}
  end

  def clear_hands(players) do
    Enum.map(players, fn {k, p} -> {k, Map.put(p, :hand, [])} end)
  end

  # Starting with the dealer, go around in a circle and give each player 4 cards
  def distribute_cards(players, _player, []), do: players

  def distribute_cards(players, player_id, [card | deck]) do
    {_, players} = Keyword.get_and_update(players, player_id, fn player ->
      { player, Map.put(player, :hand, [ card | player.hand ]) }
    end)
    distribute_cards(players, next_player(player_id), deck)
  end

  def other_team(1), do: 2
  def other_team(2), do: 1

  def next_turn(game), do: %{game | turn: next_player(game.turn)}
  def prev_turn(game), do: %{game | turn: prev_player(game.turn)}

  def next_player(:player_t1_p1), do: :player_t2_p1
  def next_player(:player_t2_p1), do: :player_t1_p2
  def next_player(:player_t1_p2), do: :player_t2_p2
  def next_player(:player_t2_p2), do: :player_t1_p1

  def prev_player(:player_t1_p1), do: :player_t2_p2
  def prev_player(:player_t2_p1), do: :player_t1_p1
  def prev_player(:player_t1_p2), do: :player_t2_p1
  def prev_player(:player_t2_p2), do: :player_t1_p2

  defp random_player(players) do
    {kw, _ } = Enum.at(players, :rand.uniform(4) - 1)
    kw
  end
end
