defmodule HukumEngine.GameServer do

  # GenServer for a game. It takes incoming calls and coordinates them with
  # the `Rules` state machine, making sure corresponding updates to the `Game`
  # state happen at the appropriate times.

  alias HukumEngine.{Game, Rules}

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_) do
    { :ok, Game.new_game(%Rules{}) }
  end

  def handle_call({:add_team, player_names}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, :add_team)
    do
      game
      |> Game.add_team(player_names)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, game}
    end
  end

  defp update_rules(game, rules), do: %{ game | rules: rules }

  defp reply_success(data, reply), do: {:reply, reply, data}
end
