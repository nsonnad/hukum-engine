defmodule HukumEngine.Application do

  @registry :game_registry

  use Application

  def start(_type, _args) do
    children = [
      { HukumEngine.GameSupervisor, [] },
      { Registry, [keys: :unique, name: @registry] }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HukumEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
