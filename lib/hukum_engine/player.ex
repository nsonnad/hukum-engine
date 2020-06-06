defmodule HukumEngine.Player do

  alias HukumEngine.Player

  defstruct(
    name: nil,
    hand: [],
    team: :unassigned
  )

  def new(name) do
    %Player{name: name}
  end
end

