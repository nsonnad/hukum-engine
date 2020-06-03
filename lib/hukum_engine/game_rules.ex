defmodule HukumEngine.Rules do
  alias __MODULE__

  # Finite state machine for managing the rules about the stages of our game.
  # The stages of a game are:
  # :waiting_for_teams
  # :call_or_pass
  # :calling?
  # more tk...

  defstruct(
    stage: :waiting_for_teams,
    team_status: {:empty, :empty}
  )

  def new(), do: %Rules{}

  def check(%Rules{stage: :waiting_for_teams} = rules, :add_team) do
    case rules.team_status do
      {:empty, :empty} ->
        {:ok, %Rules{ rules | team_status: {:filled, :empty }}}
      {:filled, :empty} ->
        {:ok, %Rules{ rules |
          team_status: {:filled, :filled}, stage: :call_or_pass }}
      {:filled, :filled} ->
        {:error, :teams_full}
    end
  end

  def check(rules, {:correct_turn, player_id, turn}) when player_id == turn do
    {:ok, rules}
  end

  def check(_rules, {:correct_turn, _player_id, _turn}) do
    {:error, :not_your_turn}
  end

  def check(%Rules{stage: :call_or_pass} = rules, :pass) do
    {:ok, rules}
  end

  def check(%Rules{stage: :call_or_pass} = rules, :calling) do
    {:ok, %{ rules | stage: :waiting_for_first_card }}
  end

  def check(%Rules{stage: :call_or_pass} = rules, :loner) do
    {:ok, %{ rules | stage: :playing_loner }}
  end

  def check(%Rules{stage: :waiting_for_first_card} = rules, :play_first_card) do
    {:ok, %{ rules | stage: :waiting_for_trump }}
  end

  def check(%Rules{stage: :waiting_for_trump} = rules, :call_trump) do
    {:ok, %{ rules | stage: :playing_hand }}
  end

  def check(%Rules{stage: :playing_hand} = rules, { :play_card, card, suit_led, hand }) do
    case Enum.member?(hand, card) && legal_card?(card, suit_led, hand) do
      true -> {:ok, rules}
      false -> {:error, :illegal_card}
    end
  end

  def check(%Rules{stage: :playing_hand} = rules, { :hand_status, _hand_trick_winners = 8}) do
    {:ok, %{ rules | stage: :end_of_hand }}
  end

  def check(%Rules{stage: :playing_hand} = rules, { :hand_status, _hand_trick_winners}) do
    {:ok, rules}
  end

  def check(%Rules{stage: :end_of_hand} = rules, { :win_status, score }) do
    case any_winner?(score) do
      true -> {:ok, %{ rules | stage: :game_over }}
      false -> {:ok, %{ rules | stage: :call_or_pass }}
    end
  end

  def check(%Rules{stage: :playing_hand} = rules, { :win_status, _score }) do
    {:ok, rules}
  end

  def check(_state, _action), do: :error

  # helpers

  defp any_winner?(score) do
    Enum.any?(Enum.map(score, fn {_team, s} -> s end), fn s -> s >= 12 end)
  end

  def legal_card?(card, suit_led, hand) do
    card.suit == suit_led ||
    !Enum.member?(suits_in_hand(hand), suit_led) ||
    suit_led == :undecided
  end

  defp suits_in_hand(hand) do
    Enum.map(hand, fn card -> card.suit end)
  end
end
