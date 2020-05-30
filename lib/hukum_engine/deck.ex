defmodule HukumEngine.Deck do
  @cards (
    for suit <- [:clubs, :diamonds, :hearts, :spades],
        rank <- [7, 8, 9, 10, :jack, :queen, :king, :ace],
      do: %{suit: suit, rank: rank}
  )

  def shuffled(), do: Enum.shuffle(@cards)
end
