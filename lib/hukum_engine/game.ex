defmodule HukumEngine.Game do
  alias HukumEngine.{Deck, Game, Player, Rules}
  import Kernel

  defstruct(
    players: [],
    score: {0, 0},
    rules: :none,
    dealer_seat: nil, # int of player index
    deck: nil,
    trump: :undecided
  )

  def new_game(rules, players \\ []) do
    %Game{
      rules: rules,
      players: players,
      dealer_seat: random_dealer()
    }
  end

  # add first team
  def add_team(game = %Game{rules: %Rules{team_status: {:empty, :empty}}}, player_names) do
    team_players = player_names |> Enum.with_index |> Enum.map(&create_player(&1, 1))
    %{game | players: team_players }
  end

  # add second team
  def add_team(game = %Game{rules: %Rules{team_status: {:filled, :empty}}}, player_names) do
    team_players = player_names |> Enum.with_index |> Enum.map(&create_player(&1, 2))
    [p1, p2, p3, p4] = game.players ++ team_players

    %{game | players: [p1, p3, p2, p4] }
    |> start_new_hand
  end

  def create_player({name, index}, team_number) do
    player_kw = player_atom(index, team_number)
    { player_kw, %Player{name: name, team: team_number }}
  end

  def start_new_hand(game) do
    deck = Enum.split(Deck.shuffled(), 16)

    players_with_cards =
      game.players
      |> distribute_cards(next_player(game.dealer_seat), elem(deck, 0))

    %{ game | players: players_with_cards, deck: elem(deck, 1) }
  end

  # Starting with the dealer, go around in a circle and give each player 4 cards
  def distribute_cards(players, _player, []), do: players

  def distribute_cards(players, player, [card | deck]) do
    {key, _} = Enum.at(players, player-1)
    {_, players} = Keyword.get_and_update(players, key, fn current ->
      { current, Map.put(current, :hand, [ card | current.hand ]) }
    end)
    distribute_cards(players, next_player(player), deck)
  end

  defp player_atom(index, team_number) do
    String.to_atom("player_t#{team_number}_p#{index+1}")
  end

  defp next_player(_player = 4), do: 1
  defp next_player(player), do: player + 1

  defp random_dealer, do: :rand.uniform(4)

end
