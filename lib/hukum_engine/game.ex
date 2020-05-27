defmodule HukumEngine.Game do
  alias HukumEngine.Game

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

  #def put_player(game, player) do

  #end

end
