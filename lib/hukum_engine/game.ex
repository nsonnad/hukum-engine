defmodule HukumEngine.Game do
  alias HukumEngine.{Game, Player}

  #@behaviour :gen_statem
  #@name: :game_statem

  defstruct(
    players: Map.new(),
    score: {0, 0},
    fsm: :none
  )

  def new_game(fsm) do
    %Game{ fsm: fsm }
  end

  def add_player(game, name) do
    {:ok, new_player} = Player.start_link(name)
    new_player_atom =
      "player" <> Integer.to_string(Kernel.map_size(game.players) + 1)
      |> String.to_atom

    %{ game | players: Map.put(game.players, new_player_atom, new_player)}
  end

  def deal_cards(game) do
    players_with_cards =
      game.players
      |> Enum.map(fn p -> Map.put(p, :hand, ["Ace!"]) end)

    %{ game | players: players_with_cards }
  end

  #defp get_player_names(%Game{ players: players }) do
    #players
    #|> Enum.map(fn x -> x["name"] end)
  #end

end
