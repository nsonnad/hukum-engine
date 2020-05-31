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

  def pass(game_pid, player_id) do
    GenServer.call(game_pid, { :pass, player_id })
  end

  def calling(game_pid, player_id) do
    GenServer.call(game_pid, { :calling, player_id })
  end

  def play_card(game_pid, player_id, team, card) do
    GenServer.call(game_pid, { :play_card, player_id, team, card })
  end
end
