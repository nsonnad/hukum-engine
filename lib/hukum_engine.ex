defmodule HukumEngine do

  def new_game() do
    {:ok, pid} = HukumEngine.GameSupervisor.start_game_server()
    pid
  end

end
