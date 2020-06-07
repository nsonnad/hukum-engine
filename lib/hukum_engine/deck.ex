defmodule HukumEngine.Deck do
  @cards (
    for suit <- [:clubs, :diamonds, :hearts, :spades],
        rank <- [:seven, :eight, :nine, :ten, :jack, :queen, :king, :ace],
      do: %{suit: suit, rank: rank}
  )

  def shuffled(), do: Enum.shuffle(@cards)

  def value(:seven), do: 7
  def value(:eight), do: 8
  def value(:nine), do: 9
  def value(:ten), do: 10
  def value(:jack), do: 11
  def value(:queen), do: 12
  def value(:king), do: 13
  def value(:ace), do: 14
end
