defmodule HukumEngine.GameServer do

  # GenServer for a game. It takes incoming calls and coordinates them with
  # the `Rules` state machine, making sure corresponding updates to the `Game`
  # state happen at the appropriate times.
  use GenServer
  require Logger

  alias HukumEngine.{Game, Rules}

  @registry :game_registry

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  def stop_game(name), do: GenServer.stop(via_tuple(name))

  def terminate(reason, game) do
    Logger.info("Exiting game #{game.id} with reason: #{inspect reason}")
  end

  def via_tuple(game_id), do: {:via, Registry, {@registry, game_id}}

  def init(game_id) do
    { :ok, Game.new_game(game_id, %Rules{}) }
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
      {:error, :teams_full} -> {:reply, {:error, :teams_full}, game}
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:pass, player_id}, _from, game) do
    with {:ok, rules}  <- Rules.check(game.rules, {:correct_turn, player_id, game.turn}),
         {:ok, _rules} <- Rules.check(rules, :pass)
    do
      case game.turn == game.dealer do
        true -> game |> Game.start_new_hand |> reply_game_data()
        false -> game |> Game.next_turn |> reply_game_data()
      end
    else
      {:error, :not_your_turn} -> {:reply, {:error, :not_your_turn}, game}
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:calling, player_id}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, {:correct_turn, player_id, game.turn}),
         {:ok, rules} <- Rules.check(rules, :calling)
    do
      game
      |> Game.next_turn
      |> update_rules(rules)
      |> reply_game_data()
    else
      {:error, :not_your_turn} -> {:reply, {:error, :not_your_turn}, game}
      :error -> {:reply, :error, game}
    end
  end

  ## TODO: loner
  def handle_call({:loaner, player_id}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, {:correct_turn, player_id, game.turn}),
         {:ok, rules} <- Rules.check(rules, :loaner)
    do
      game |> update_rules(rules) |> reply_game_data()
    else
      {:error, :not_your_turn} -> {:reply, {:error, :not_your_turn}, game}
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:play_first_card, player_id, card}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, {:correct_turn, player_id, game.turn}),
         {:ok, rules} <- Rules.check(rules, :play_first_card)
    do
      game
      |> Game.play_card(player_id, card)
      |> Game.set_suit_led(card.suit)
      |> Game.prev_turn
      |> update_rules(rules)
      |> reply_game_data()
    else
      {:error, :not_your_turn} -> {:reply, {:error, :not_your_turn}, game}
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:call_trump, player_id, trump, team}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, {:correct_turn, player_id, game.turn}),
         {:ok, rules} <- Rules.check(rules, :call_trump)
    do
      game
      |> Game.set_trump(trump, team)
      |> Game.deal_second_set
      |> Game.next_turn
      |> Game.next_turn
      |> update_rules(rules)
      |> reply_game_data()
    else
      {:error, :not_your_turn} -> {:reply, {:error, :not_your_turn}, game}
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:play_card, player_id, card}, _from, game) do
    player_hand = Keyword.get(game.players, player_id).hand
    with {:ok, rules} <- Rules.check(game.rules, {:correct_turn, player_id, game.turn}),
         {:ok, rules} <- Rules.check(rules, {:play_card, card, game.suit_led, player_hand }),
         {:ok, game}  <- Game.play_card(game, player_id, card)
                         |> Game.check_trick,
         {:ok, rules} <- Rules.check(rules, {:hand_status, length(game.hand_trick_winners)}),
         {:ok, game}  <- game
                         |> Game.check_hand,
         {:ok, rules} <- Rules.check(rules, {:win_status, game.score})
    do
      game
      |> update_rules(rules)
      |> reply_game_data()
    else
      {:error, :not_your_turn} -> {:reply, {:error, :not_your_turn}, game}
      {:error, :illegal_card} -> {:reply, {:error, :illegal_card}, game}
      :error -> {:reply, :error, game}
    end
  end

  defp update_rules(game, rules), do: %{ game | rules: rules }

  defp reply_success(data, reply), do: {:reply, reply, data}

  defp reply_game_data(game), do: {:reply, Game.game_state_reply(game), game}
end
