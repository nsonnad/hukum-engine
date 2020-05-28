defmodule HukumEngine.GameServer do

  # GenServer for a game. It takes incoming calls and coordinates them with
  # the `Rules` state machine, making sure corresponding updates to the `Game`
  # state happen at the appropriate times.

  defstruct fsm: :none

  alias HukumEngine.{Game, Rules}

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    { :ok, Game.new_game(%Rules{}) }
  end

  def handle_call({:add_player, player_name}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, :add_player)
    do
      game
      |> Game.add_player(player_name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, game}
    end
  end

  #def handle_call({:select_team, player_id, team}, _from, game) do
    #Rules.add_player(game.fsm)
    #|> add_player_reply(game, player_name)
  #end

  defp update_rules(game, rules), do: %{game | rules: rules}

  defp reply_success(data, reply) do
    {:reply, reply, data}
  end

  #defp add_player_reply(:ok, game, player_name) do
    #game = Game.add_player(game, player_name)
    #{:reply, :ok, game}
  #end

  #defp add_player_reply(reply, game, _player_name) do
    #{:reply, reply, game}
  #end
  #def handle_call({ :tally }, _from, game) do
    #{ :reply, Game.tally(game), game }
  #end
end
