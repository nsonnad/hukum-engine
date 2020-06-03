defmodule HukumEngine do

  def new_game() do
    {:ok, pid} = HukumEngine.GameSupervisor.start_game_server()
    pid
  end

  def get_game_state(game_pid) do
    GenServer.call(game_pid, { :get_game_state })
  end

  def add_team(game_pid, player_names) do
    GenServer.call(game_pid, { :add_team, player_names })
  end

  def call_or_pass(game_pid, player_id, choice) do
    GenServer.call(game_pid,  { choice, player_id })
  end

  def loner(game_pid) do
    GenServer.call(game_pid, { :loner })
  end

  def play_first_card(game_pid, player_id, card) do
    GenServer.call(game_pid, { :play_first_card, player_id, card })
  end

  def call_trump(game_pid, player_id, trump, team) do
    GenServer.call(game_pid, { :call_trump, player_id, trump, team })
  end

  def play_card(game_pid, player_id, card) do
    GenServer.call(game_pid, { :play_card, player_id, card })
  end
end
