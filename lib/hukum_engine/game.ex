defmodule HukumEngine.Game do
  alias HukumEngine.{Deck, Game, Player, Rules}
  import Kernel

  @deck_size 32

  defstruct(
    players: [],
    score: {0, 0},
    rules: :none,
    dealer: nil,
    leader: nil,
    deck: nil,
    turn: nil,
    trump: :undecided
  )

  def new_game(rules, players \\ []) do
    %Game{
      rules: rules,
      players: players
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

    # arrange players by seat order
    [p1, p2, p3, p4] = game.players ++ team_players
    players = [p1, p3, p2, p4]

    %{game | players: players, dealer: random_player(players) }
    |> start_new_hand
  end

  def create_player({ name, index }, team_number) do
    player_kw = String.to_atom("player_t#{team_number}_p#{index+1}")
    { player_kw, %Player{name: name, team: team_number }}
  end

  def start_new_hand(game) do
    deck = Enum.split(Deck.shuffled(), div(@deck_size, 2))
    leader = next_player(game.dealer)

    %{ game |
      players: distribute_cards(game.players, leader, elem(deck, 0)),
      deck: elem(deck, 1),
      leader: leader,
      turn: leader }
  end

  # Starting with the dealer, go around in a circle and give each player 4 cards
  def distribute_cards(players, _player, []), do: players

  def distribute_cards(players, player_kw, [card | deck]) do
    {_, players} = Keyword.get_and_update(players, player_kw, fn player ->
      { player, Map.put(player, :hand, [ card | player.hand ]) }
    end)
    distribute_cards(players, next_player(player_kw), deck)
  end

  def next_player(:player_t1_p1), do: :player_t2_p1
  def next_player(:player_t2_p1), do: :player_t1_p2
  def next_player(:player_t1_p2), do: :player_t2_p2
  def next_player(:player_t2_p2), do: :player_t1_p1

  defp random_player(players) do
    {kw, _ } = Enum.at(players, :rand.uniform(4) - 1)
    kw
  end
end
