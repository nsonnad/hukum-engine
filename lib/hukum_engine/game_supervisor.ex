defmodule HukumEngine.GameSupervisor do
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game_server() do
    spec = {HukumEngine.Server, []}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

end
