defmodule HukumEngine.Game do
  alias HukumEngine.{Deck, Game, Player}
  import Kernel

  defstruct(
    players: Map.new(),
    score: nil,
    rules: :none,
    dealer: nil,
    deck: nil
  )

  def new_game(rules) do
    %Game{ rules: rules }
  end

  def add_player(game, name) do
    new_player_atom = create_player_atom(map_size(game.players))
    %{ game |
      players: Map.put(game.players, new_player_atom, %Player{ name: name }
    )}
  end

  def assign_team(game, player_id, team_number) do
    put_in(
      game,
      [Access.key(:players), player_id, Access.key(:team)],
      team_number
    )
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

  defp create_player_atom(player_number) do
    "player" <> Integer.to_string(player_number + 1)
    |> String.to_atom
  end

end
