defmodule HukumEngine.GameServer do

  defstruct fsm: :none

  alias HukumEngine.{Game, Rules}

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    { :ok, fsm } = Rules.start_link()
    { :ok, Game.new_game(fsm) }
  end

  def handle_call({:add_player, player_name}, _from, game) do
    Rules.add_player(game.fsm)
    |> add_player_reply(game, player_name)
  end

  #def handle_call({:select_team, player_id, team}, _from, game) do
    #Rules.add_player(game.fsm)
    #|> add_player_reply(game, player_name)
  #end

  defp add_player_reply(:players_ready, game, player_name) do
    game = game
    |> Game.add_player(player_name)

    {:reply, :ok, game}
  end

  defp add_player_reply(:ok, game, player_name) do
    game = Game.add_player(game, player_name)
    {:reply, :ok, game}
  end

  defp add_player_reply(reply, game, _player_name) do
    {:reply, reply, game}
  end
  #def handle_call({ :tally }, _from, game) do
    #{ :reply, Game.tally(game), game }
  #end
end
