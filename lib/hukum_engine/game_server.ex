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

  def handle_call({:pass, player_id}, _from, game) do
    with {:ok, _rules} <- Rules.check(game.rules, { :pass, player_id, game.turn })
    do
      case player_id == game.dealer do
        true -> game |> Game.start_new_hand |> reply_game_data()
        false -> game |> Game.next_turn |> reply_game_data()
      end
    else
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({ :get_game_state }, _from, game) do
    reply_game_data(game)
  end

  defp update_rules(game, rules), do: %{ game | rules: rules }

  defp reply_success(data, reply), do: {:reply, reply, data}

  defp reply_game_data(game), do: {:reply, Game.game_state_reply(game), game}
end
