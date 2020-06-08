defmodule HukumEngine.Game do
  alias HukumEngine.{Deck, Game, Player}
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
    %Game{
      id: game_id,
      rules: rules,
      players: players
    }
  end

  # add first team
  def add_player(game, player_name) do
    %{game | players: [ create_player(player_name) | game.players ] }
  end

  def remove_player(game, player_name) do
    %{game | players: Keyword.delete(game.players, player_name) }
  end

  def create_player(player_name) do
    { player_name, Player.new(Atom.to_string(player_name))}
  end

  def choose_team(game, player_name, team) do
    players = Keyword.update(game.players, player_name, [], fn p ->
      %{p | team: team}
    end)
    %{ game | players: players }
  end

  def start_new_hand(game) do
    deck = Enum.split(Deck.shuffled(), div(@deck_size, 2))
    turn = next_player(game.players, game.dealer)
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
        new_winner_score = Map.get(game.score, winning_team) + points_to_add(winning_team, game.calling_team)
        new_score = Map.put(game.score, winning_team, new_winner_score)

        game = %{game |
          score: new_score,
          suit_led: :undecided,
          dealer: assign_new_dealer(game.dealer, game.players, new_score)
        } |> start_new_hand

        {:ok, game}

      false ->
        {:ok, game}
    end
  end

  def sort_players(game) do
    {t1, t2} = Enum.split_with(game.players, fn {_k, p} -> p.team == 1 end)

    # start with 1 instead of 0 becuase [ head | tail ] operation puts new
    # elements at the beginning
    %{game | players: [Enum.at(t1, 1), Enum.at(t2, 1), Enum.at(t1, 0), Enum.at(t2, 0)]}
  end

  def assign_random_dealer(game) do
    %{ game | dealer: random_player(game.players) }
  end

  def assign_new_dealer(old_dealer, players, score) do
    [score1, score2] = Map.values(score)
    case score1 == score2 do
      true -> old_dealer
      false -> losing_team_dealer(players, score)
    end
  end

  def losing_team_dealer(players, score) do
    {losing_team, _} = Enum.min_by(score, fn {team, points} -> points end)

    players
    |> Enum.filter(fn {_k, p} -> p.team == losing_team end)
    |> Enum.random
    |> Kernel.elem(0)
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

  def set_trump(game, player_id, trump) do
    calling_team = Keyword.get(game.players, player_id).team
    %{ game | suit_trump: trump, calling_team: calling_team }
  end

  def game_state_reply(game) do
    %{
      id: game.id,
      stage: game.rules.stage,
      players: game.players,
      turn: game.turn,
      dealer: game.dealer,
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
    players = Keyword.update(players, player_id, [], fn player ->
      Map.put(player, :hand, [ card | player.hand ])
    end)
    distribute_cards(players, next_player(players, player_id), deck)
  end

  def other_team(1), do: 2
  def other_team(2), do: 1

  def next_turn(game), do: %{game | turn: next_player(game.players, game.turn)}
  def prev_turn(game), do: %{game | turn: prev_player(game.players, game.turn)}

  def next_player(players, player_name) do
    player_keys = Keyword.keys(players)
    curr_index = Enum.find_index(player_keys, fn k -> k == player_name end)
    Enum.at(player_keys, next_player_index(curr_index))
  end

  def prev_player(players, player_name) do
    player_keys = Keyword.keys(players)
    curr_index = Enum.find_index(player_keys, fn k -> k == player_name end)
    Enum.at(player_keys, prev_player_index(curr_index))
  end

  def next_player_index(3), do: 0
  def next_player_index(ix), do: ix + 1

  def prev_player_index(0), do: 3
  def prev_player_index(ix), do: ix - 1

  defp random_player(players) do
    {kw, _ } = Enum.at(players, :rand.uniform(4) - 1)
    kw
  end
end
