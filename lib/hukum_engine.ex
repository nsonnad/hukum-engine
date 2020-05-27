defmodule HukumEngine do

  def new_game() do
    {:ok, pid} = HukumEngine.GameSupervisor.start_game_server()
    pid
  end

  def put_player(game_pid, player_name) do
    GenServer.call(game_pid, { :put_player, player_name })
  end

end
