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

  def handle_call({ :get_game_state }, _from, game) do
    reply_game_data(game)
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

  def handle_call({:pass}, _from, game) do
    with {:ok, _rules} <- Rules.check(game.rules, :pass)
    do
      case game.turn == game.dealer do
        true -> game |> Game.start_new_hand |> reply_game_data()
        false -> game |> Game.next_turn |> reply_game_data()
      end
    else
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:calling}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, :calling)
    do
      game
      |> Game.next_turn
      |> update_rules(rules)
      |> reply_game_data()
    else
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:play_first_card, player_id, team, card}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, :play_first_card)
    do
      game
      |> Game.play_card(player_id, team, card)
      |> Game.prev_turn
      |> update_rules(rules)
      |> reply_game_data()
    else
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:call_trump, trump, team}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, :call_trump)
    do
      game
      |> Game.set_trump(trump, team)
      |> Game.next_turn
      |> Game.next_turn
      |> update_rules(rules)
      |> reply_game_data()
    else
      :error -> {:reply, :error, game}
    end
  end

  #def handle_call({:play_card, player_id, team, card}, _from, game) do
    #with {:ok, rules} <- Rules.check(game.rules, :play_card)
    #do
      #game
      #|> Game.play_card(player_id, team, card)
      #|> update_rules(rules)
    #else
      #:error -> {:reply, :error, game}
    #end
  #end

  defp update_rules(game, rules), do: %{ game | rules: rules }

  defp reply_success(data, reply), do: {:reply, reply, data}

  defp reply_game_data(game), do: {:reply, Game.game_state_reply(game), game}
end
