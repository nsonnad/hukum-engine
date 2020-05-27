defmodule HukumEngine.Player do

  alias HukumEngine.Player

  defstruct(
    name: nil,
    hand: [],
    team: nil
  )

  def start_link(name \\ :none) do
    Agent.start_link(fn -> %Player{ name: name } end)
  end

  def set_name(player, name) do
    Agent.update(player, fn state -> Map.put(state, :name, name) end)
  end

  def set_hand(player, hand) do
    Agent.update(player, fn state -> Map.put(state, :hand, hand) end)
  end

end

