defmodule HukumEngine.Player do

  alias HukumEngine.Player

  defstruct(
    name: nil,
    hand: [],
    team: :unassigned
  )

  def new(name, team_number) do
    %Player{name: name, team: team_number}
  end
end

