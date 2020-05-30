defmodule HukumEngine do

  def new_game() do
    {:ok, pid} = HukumEngine.GameSupervisor.start_game_server()
    pid
  end

  def add_team(game_pid, player_names) do
    GenServer.call(game_pid, { :add_team, player_names })
  end

end
