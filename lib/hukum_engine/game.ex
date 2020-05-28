defmodule HukumEngine.Game do
  alias HukumEngine.{Game, Player}

  defstruct(
    players: Map.new(),
    score: {0, 0},
    rules: :none
  )

  def new_game(rules) do
    %Game{ rules: rules }
  end

  def add_player(game, name) do
    new_player_atom = create_player_atom(Kernel.map_size(game.players))
    %{ game |
      players: Map.put(game.players, new_player_atom, %Player{ name: name }
    )}
  end

  def assign_team(game, player_id, team_number) do
    Kernel.put_in(game, ["players", player_id, "team"], team_number)
  end

  def deal_cards(game) do
    players_with_cards =
      game.players
      |> Enum.map(fn p -> Map.put(p, :hand, ["Ace!"]) end)

    %{ game | players: players_with_cards }
  end

  defp create_player_atom(player_number) do
    "player" <> Integer.to_string(player_number + 1)
    |> String.to_atom
  end

end
