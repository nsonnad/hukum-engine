defmodule HukumEngine.Deck do
  @cards (
    for suit <- [:clubs, :diamonds, :hearts, :spades],
        rank <- [7, 8, 9, 10, :jack, :queen, :king, :ace],
      do: %{suit: suit, rank: rank}
  )

  def shuffled(), do: Enum.shuffle(@cards)

  def value(num) when num in 7..10, do: num
  def value(:jack), do: 11
  def value(:queen), do: 12
  def value(:king), do: 13
  def value(:ace), do: 14
end
