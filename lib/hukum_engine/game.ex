defmodule HukumEngine.Game do
  alias HukumEngine.Game
  alias HukumEngine.Player

  #@behaviour :gen_statem
  #@name: :game_statem

  defstruct(
    players: MapSet.new(),
    score: {0, 0},
    stage: :initializing
  )

  def new_game() do
    %Game{
      stage: :waiting_for_players
    }
  end

  def put_player(game = %Game{ :stage => :playing}, _player_name) do
    game
  end

  def put_player(game = %Game{ :stage => :waiting_for_players}, player_name) do
    case MapSet.size(game.players) do
      3 ->
        %{ game |
          players: MapSet.put(game.players, %Player{ name: player_name }),
          stage: :playing
        }
      _ ->
        %{ game |
          players: MapSet.put(game.players, %Player{ name: player_name })
        }
    end
  end

  #defp get_player_names(%Game{ players: players }) do
    #players
    #|> Enum.map(fn x -> x["name"] end)
  #end

end
