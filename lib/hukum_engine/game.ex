defmodule HukumEngine.Game do
  alias HukumEngine.{Game, Player, Rules}
  import Kernel

  defstruct(
    players: [],
    score: nil,
    rules: :none,
    dealer: nil,
    deck: nil
  )

  def new_game(rules) do
    %Game{ rules: rules }
  end

  def add_team(game = %Game{rules: %Rules{team_status: {:empty, :empty}}}, player_names) do
    team_players = Enum.map(player_names, &create_player(&1, 1))
    %{game | players: [team_players | game.players] }
  end

  def add_team(game = %Game{rules: %Rules{team_status: {:filled, :empty}}}, player_names) do
    team_players = Enum.map(player_names, &create_player(&1, 2))
    %{game | players: [team_players | game.players]}
  end

  def create_player(name, team_number) do
    %Player{name: name, team: team_number }
  end

  def reset_score(game) do
    %{ game | score: {0, 0}}
  end

  def assign_dealer(game) do
    %{ game | dealer: Enum.random(Map.keys(game.players)) }
  end

  def deal_cards(game) do
    players_with_cards =
      game.players
      |> Enum.map(fn p -> Map.put(p, :hand, ["Ace!"]) end)

    %{ game | players: players_with_cards }
  end

  def deal_cards(game, _), do: game

end
