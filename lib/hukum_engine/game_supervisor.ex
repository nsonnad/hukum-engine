defmodule HukumEngine.GameSupervisor do
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game_server(game_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      %{
        id: HukumEngine.GameServer,
        start: { HukumEngine.GameServer, :start_link, [game_id] },
        restart: :transient
      }
    )
  end

end
