defmodule AutoTestGame do

  alias HukumEngine.{Game, Rules}

  @suits [:clubs, :diamonds, :hearts, :spades]
  @call_or_pass [:pass, :calling]
  @timer_wait 1

  def run do
    pid = HukumEngine.new_game()
    HukumEngine.add_team(pid, ["player1", "player2"])
    HukumEngine.add_team(pid, ["player3", "player4"])
    game = HukumEngine.get_game_state(pid)
    start_hand({game, pid})
  end

  def start_hand({game, pid}) do
  IO.puts("starting new hand...")

  { game, pid }
  |> decide_trump(Enum.random(@call_or_pass))
  |> first_card
  |> call_trump
  |> play_tricks
  end

  def decide_trump({game, pid}, :pass) do
    :timer.sleep(:rand.uniform(:timer.seconds(@timer_wait)))
    color_str(:yellow, "#{game.turn} decides to pass...\n")
    game = HukumEngine.call_or_pass(pid, :pass)
    decide_trump({game, pid}, Enum.random(@call_or_pass))
  end

  def decide_trump({game, pid}, :calling) do
    :timer.sleep(:rand.uniform(:timer.seconds(@timer_wait)))
    color_str(:green, "#{game.turn} decides to call...\n")
    {HukumEngine.call_or_pass(pid, :calling), pid}
  end

  def first_card({game, pid}) do
    :timer.sleep(:rand.uniform(:timer.seconds(@timer_wait)))
    color_str(:blue, "#{game.turn} playing first card...\n")
    p = Keyword.get(game.players, game.turn)
    {HukumEngine.play_first_card(pid, game.turn, p.team, Enum.random(p.hand)), pid}
  end

  def call_trump({game, pid}) do
    :timer.sleep(:rand.uniform(:timer.seconds(@timer_wait)))
    trump = Enum.random(@suits)
    {_, _, initial_card} = Enum.at(game.current_trick, 0)
    color_str(:green, "#{game.turn} calls #{trump}\n")
    :timer.sleep(:rand.uniform(:timer.seconds(@timer_wait)))
    color_str(:magenta, "First card was: #{initial_card.rank} of #{initial_card.suit}\n")
    p = Keyword.get(game.players, game.turn)
    {HukumEngine.call_trump(pid, trump, p.team), pid}
  end

  def play_tricks({game = %{stage: :playing_hand, suit_led: :undecided}, pid}) do
    :timer.sleep(:rand.uniform(:timer.seconds(@timer_wait)))
    p = Keyword.get(game.players, game.turn)
    card_to_play = best_valid_card(game.suit_trump, game.suit_led, p.hand)
    color_str(:magenta, "#{game.turn} leads: #{card_to_play.rank} of #{card_to_play.suit}\n")
    game = HukumEngine.play_card(pid, game.turn, p.team, card_to_play)
    play_tricks({game, pid})
  end

  def play_tricks({game = %{stage: :playing_hand}, pid}) do
    :timer.sleep(:rand.uniform(:timer.seconds(@timer_wait)))
    p = Keyword.get(game.players, game.turn)
    card_to_play = best_valid_card(game.suit_trump, game.suit_led, p.hand)
    color_str(:blue, "#{game.turn} plays: #{card_to_play.rank} of #{card_to_play.suit}\n")
    game = HukumEngine.play_card(pid, game.turn, p.team, card_to_play)
    play_tricks({game, pid})
  end

  def play_tricks({game = %{stage: :call_or_pass}, pid}) do
    color_str(:magenta, "Hand over. New score:")
    IO.inspect game.score
    IO.puts "\n"

    start_hand({game, pid})
  end

  def play_tricks({game = %{stage: :game_over}, _pid}) do
    IO.puts("Game Over.")
    IO.puts("Score:")
    IO.inspect game.score
  end
  # helpers

  defp best_valid_card(suit_trump, suit_led, hand) do
    valid = Enum.filter(hand, fn card -> Rules.legal_card?(card, suit_led, hand) end)
    Enum.max_by(valid, fn card ->
      Game.score_card(card.rank, card.suit, suit_trump, suit_led)
    end)
  end

  defp color_str(color, str) do
    IO.puts IO.ANSI.format([:black_background, color, str])
  end
end
