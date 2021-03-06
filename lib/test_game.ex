defmodule AutoTestGame do

  alias HukumEngine.{Game, GameServer, Rules}

  @suits [:clubs, :diamonds, :hearts, :spades]
  @call_or_pass [:pass, :calling]

  def run do
    game_id = "game_1"
    HukumEngine.new_game(game_id)
    HukumEngine.add_player(via(game_id), :john)
    HukumEngine.add_player(via(game_id), :paul)
    HukumEngine.add_player(via(game_id), :george)
    HukumEngine.add_player(via(game_id), :ringo)

    HukumEngine.choose_team(via(game_id), :john, 1)
    HukumEngine.choose_team(via(game_id), :george, 1)
    HukumEngine.choose_team(via(game_id), :paul, 2)
    HukumEngine.choose_team(via(game_id), :ringo, 2)

    HukumEngine.confirm_teams(via(game_id))

    {:ok, game} = HukumEngine.get_game_state(via(game_id))
    start_hand({game, via(game_id)})
  end

  def start_hand({game, game_id}) do
    IO.puts("starting new hand...\n")
    IO.puts("dealer is #{game.dealer} from team #{Keyword.get(game.players, game.dealer).team}\n")

    { game, game_id }
    |> decide_trump(Enum.random(@call_or_pass))
    |> first_card
    |> call_trump
    |> play_tricks
  end

  def decide_trump({game, game_id}, :pass) do
    color_str(:yellow, "#{game.turn} decides to pass...\n")
    {:ok, game} = HukumEngine.call_or_pass(game_id, game.turn, :pass)
    decide_trump({game, game_id}, Enum.random(@call_or_pass))
  end

  def decide_trump({game, game_id}, :calling) do
    color_str(:green, "#{game.turn} decides to call...\n")
    {:ok, new_game} = HukumEngine.call_or_pass(game_id, game.turn, :calling)
    {new_game, game_id}
  end

  def first_card({game, game_id}) do
    color_str(:blue, "#{game.turn} playing first card...\n")
    p = Keyword.get(game.players, game.turn)
    {:ok, new_game} = HukumEngine.play_card(game_id, game.turn, Enum.random(p.hand))
    {new_game, game_id}
  end

  def call_trump({game, game_id}) do
    trump = Enum.random(@suits)
    initial_card = Enum.at(game.current_trick, 0)
    color_str(:green, "#{game.turn} calls #{trump}\n")
    color_str(:magenta, "First card was: #{initial_card.rank} of #{initial_card.suit}\n")
    {:ok, new_game} = HukumEngine.call_trump(game_id, game.turn, trump)
    {new_game, game_id}
  end

  def play_tricks({game = %{stage: :playing_hand, suit_led: :undecided}, game_id}) do
    p = Keyword.get(game.players, game.turn)
    card_to_play = best_valid_card(game.suit_trump, game.suit_led, p.hand)

    IO.puts "previous trick\n"
    IO.inspect game.current_trick

    color_str(:magenta, "#{game.turn} leads: #{card_to_play.rank} of #{card_to_play.suit}\n")
    {:ok, game} = HukumEngine.play_card(game_id, game.turn, card_to_play)
    play_tricks({game, game_id})
  end

  def play_tricks({game = %{stage: :playing_hand}, game_id}) do
    p = Keyword.get(game.players, game.turn)
    card_to_play = best_valid_card(game.suit_trump, game.suit_led, p.hand)
    color_str(:blue, "#{game.turn} plays: #{card_to_play.rank} of #{card_to_play.suit}\n")
    {:ok, game} = HukumEngine.play_card(game_id, game.turn, card_to_play)
    play_tricks({game, game_id})
  end

  def play_tricks({game = %{stage: :call_or_pass}, game_id}) do
    color_str(:magenta, "Hand over. New score:")
    IO.inspect game.score
    IO.puts "\n"

    start_hand({game, game_id})
  end

  def play_tricks({game = %{stage: :game_over}, _game_id}) do
    IO.puts("Game Over.")
    IO.puts("Score:")
    IO.inspect game.score
  end
  # helpers
  defp via(game_id), do: GameServer.via_tuple(game_id)

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
