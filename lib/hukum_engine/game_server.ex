defmodule HukumEngine.GameServer do

  # GenServer for a game. It takes incoming calls and coordinates them with
  # the `Rules` state machine, making sure corresponding updates to the `Game`
  # state happen at the appropriate times.
  use GenServer, restart: :transient
  require Logger

  alias HukumEngine.{Game, Rules}

  @timeout 600_000
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

  def handle_call({:add_player, player_name}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, {:add_player, player_name, game.players})
    do
      game
      |> Game.add_player(player_name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      {:error, :game_full} -> {:reply, {:error, :game_full}, game}
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:remove_player, player_name}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, :remove_player)
    do
      game
      |> Game.remove_player(player_name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:choose_team, player_name, team}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, {:choose_team, team, team_counts(game.players)})
    do
      game = game
      |> Game.choose_team(player_name, team)
      |> update_rules(rules)

      {:reply, {:ok, %{team_counts: team_counts(game.players)}}, game}
    else
      {:error, :teams_full} -> {:reply, {:error, :teams_full}, game}
      {:error, :team_full} -> {:reply, {:error, :team_full}, game}
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:confirm_teams}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, {:confirm_teams, team_counts(game.players)})
    do
      game
      |> Game.sort_players
      |> Game.assign_random_dealer
      |> Game.start_new_hand
      |> Game.sort_hands
      |> update_rules(rules)
      |> reply_game_data()
    else
      {:error, :teams_not_filled} -> {:reply, {:error, :teams_not_filled}, game}
      :error -> {:reply, :error, game}
    end
  end

  def handle_call({:pass, player_id}, _from, game) do
    with {:ok, rules}  <- Rules.check(game.rules, {:correct_turn, player_id, game.turn}),
         {:ok, _rules} <- Rules.check(rules, :pass)
    do
      case game.turn == game.dealer do
        true ->
          game
          |> Game.start_new_hand
          |> Game.sort_hands
          |> reply_game_data()
        false ->
          game
          |> Game.next_turn
          |> reply_game_data()
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
  def handle_call({:loner, player_id}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, {:correct_turn, player_id, game.turn}),
         {:ok, rules} <- Rules.check(rules, :loaner)
    do
      game |> update_rules(rules) |> reply_game_data()
    else
      {:error, :not_your_turn} -> {:reply, {:error, :not_your_turn}, game}
      :error -> {:reply, :error, game}
    end
  end

  # after first card is played, caller announces trump
  def handle_call({:call_trump, player_id, trump}, _from, game) do
    with {:ok, rules} <- Rules.check(game.rules, {:correct_turn, player_id, game.turn}),
         {:ok, rules} <- Rules.check(rules, :call_trump)
    do
      game
      |> Game.set_trump(player_id, trump)
      |> Game.deal_second_set
      |> Game.sort_hands
      |> Game.next_turn
      |> Game.next_turn
      |> update_rules(rules)
      |> reply_game_data()
    else
      {:error, :not_your_turn} -> {:reply, {:error, :not_your_turn}, game}
      :error -> {:reply, :error, game}
    end
  end

  # the first card has different rules than other cards:
  # it sends the turn back to the caller, who then calls
  def handle_call(
    {:play_card, player_id, card},
    _from,
    game = %Game{rules: %Rules{stage: :waiting_for_first_card}})
  do
    with {:ok, rules} <- Rules.check(game.rules, {:correct_turn, player_id, game.turn}),
         {:ok, rules} <- Rules.check(rules, :play_card)
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

  # all cards but the first are handled the same way
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

  def handle_cast({:end_game}, game) do
    {:stop, :normal, game}
  end

  defp team_counts(players) do
    [1, 2]
    |> Enum.map(fn num ->
      length(Enum.filter(Keyword.values(players), fn p -> p.team == num end))
    end)
  end

  defp update_rules(game, rules), do: %{ game | rules: rules }

  defp reply_success(data, reply), do: {:reply, reply, data, @timeout}

  defp reply_game_data(game), do: {:reply, {:ok, Game.game_state_reply(game) }, game}
end
