defmodule HukumEngine do

  def new_game() do
    {:ok, pid} = HukumEngine.GameSupervisor.start_game_server()
    pid
  end

  def add_player(game_pid, player_name) do
    GenServer.call(game_pid, { :add_player, player_name })
  end

  def choose_team(game_pid, player_id, team) do
    GenServer.call(game_pid, { :choose_team, player_id, team })
  end

end
