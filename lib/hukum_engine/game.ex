defmodule HukumEngine.Game do
  alias HukumEngine.{Deck, Game, Player, Rules}
  import Kernel

  @deck_size 32

  defstruct(
    players: [],
    score: {0, 0},
    rules: :none,
    dealer: nil,
    deck: nil,
    turn: nil,
    calling_team: nil,
    current_trick: [],
    hand_tricks: %{1 => 0, 2 => 0},
    suit_led: :undecided,
    suit_trump: :undecided
  )

  def new_game(rules, players \\ []) do
    %Game{ rules: rules, players: players }
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
      deck: elem(deck, 1),
      turn: turn }
  end

  def play_card(game, player_id, team, card) do
    current_trick = [ {player_id, team, card} | game.current_trick ]

    case length(current_trick) == 4 do
      true ->
        {hi_player, hi_team, _hi_card} = get_highest_card(game.current_trick, game.trump, game.suit_led)
        %{game |
          current_trick: [],
          hand_tricks: [ hi_team | game.hand_tricks ],
          leader: hi_player
        }
      false ->
        %{game | current_trick: current_trick }
    end
  end

  def get_highest_card(trick, trump, suit_led) do
    Enum.max_by(trick, fn {_player, _team, card} ->
      score_card(card.rank, card.suit, trump, suit_led)
    end)
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
      players: game.players,
      turn: game.turn,
      score: game.score,
      current_trick: game.current_trick,
      suit_trump: game.suit_trump
    }
  end

  # helpers
  # ===============================

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
