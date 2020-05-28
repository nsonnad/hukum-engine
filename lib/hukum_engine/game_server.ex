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
      |> update_or_transition(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:choose_team, player_id, team}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, { :choose_team, player_id, team })
    do
      game
      |> Game.assign_team(player_id, team)
      |> update_or_transition(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, game}
      {:error, :team_full} -> {:reply, {:error, :team_full}, game}
      {:error, :already_assigned} -> {:reply, {:error, :already_assigned}, game}
    end
  end

  defp update_or_transition(game, rules) do
    case game.rules.stage != rules.stage do
      true ->
        stage_transition(game, rules)
      false ->
        update_rules(game, rules)
    end
  end

  def stage_transition(game, rules = %{stage: :start_game}) do
    game
    |> Game.reset_score()
    |> Game.assign_dealer()
    |> Game.deal_cards()
    |> update_rules(rules)
  end

  def stage_transition(game, rules) do
    game
    |> update_rules(rules)
  end

  defp update_rules(game, rules), do: %{ game | rules: rules }

  defp reply_success(data, reply) do
    {:reply, reply, data}
  end
end
