defmodule HukumEngine.Server do

  alias HukumEngine.Game

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    { :ok, Game.new_game() }
  end

  def handle_call({ :put_player, player_name }, _from, game) do
    game = Game.put_player(game, player_name)
    { :reply, game, game }
  end

  #def handle_call({ :tally }, _from, game) do
    #{ :reply, Game.tally(game), game }
  #end
end
