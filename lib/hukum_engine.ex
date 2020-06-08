defmodule HukumEngine do

  def new_game(game_id) do
    HukumEngine.GameSupervisor.start_game_server(game_id)
  end

  def get_game_state(game) do
    GenServer.call(game, { :get_game_state })
  end

  def add_player(game, player_name) do
    GenServer.call(game, { :add_player, player_name })
  end

  def remove_player(game, player_name) do
    GenServer.call(game, { :remove_player, player_name })
  end

  def choose_team(game, player_name, team) do
    GenServer.call(game, { :choose_team, player_name, team })
  end

  def confirm_teams(game) do
    GenServer.call(game, { :confirm_teams })
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

  def end_game(game) do
    GenServer.cast(game, { :end_game })
  end

  #def rematch(game, players) do
    #GenServer.call(game, { :rematch, players })
  #end

end
