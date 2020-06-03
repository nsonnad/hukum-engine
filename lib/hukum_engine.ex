defmodule HukumEngine do

  def new_game(game_id) do
    HukumEngine.GameSupervisor.start_game_server(game_id)
  end

  def get_game_state(game) do
    GenServer.call(game, { :get_game_state })
  end

  def add_team(game, player_names) do
    GenServer.call(game, { :add_team, player_names })
  end

  def call_or_pass(game, player_id, choice) do
    GenServer.call(game,  { choice, player_id })
  end

  def loner(game) do
    GenServer.call(game, { :loner })
  end

  def play_first_card(game, player_id, card) do
    GenServer.call(game, { :play_first_card, player_id, card })
  end

  def call_trump(game, player_id, trump, team) do
    GenServer.call(game, { :call_trump, player_id, trump, team })
  end

  def play_card(game, player_id, card) do
    GenServer.call(game, { :play_card, player_id, card })
  end

  #def rematch(game, players) do
    #GenServer.call(game, { :rematch, players })
  #end

end
