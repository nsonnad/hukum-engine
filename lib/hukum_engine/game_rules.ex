defmodule HukumEngine.Rules do
  alias __MODULE__

  # Finite state machine for managing the rules about the stages of our game.
  # The stages of a game are:
  # :waiting_for_teams
  # :call_or_pass
  # :calling?
  # more tk...

  defstruct(
    stage: :waiting_for_players
  )

  def new(), do: %Rules{}

  def check(%Rules{stage: :waiting_for_players} = _rules, {:add_player, _player_name, players})
  when length(players) == 4 do
    {:error, :game_full}
  end

  def check(%Rules{stage: :waiting_for_players} = rules, {:add_player, player_name, players})
  when length(players) == 3 do
    case !username_taken?(players, player_name) do
      true -> {:ok, %Rules{ rules | stage: :choosing_teams}}
      false -> {:error, :username_taken}
    end
  end

  def check(%Rules{stage: :waiting_for_players} = rules, {:add_player, player_name, players}) do
    case !username_taken?(players, player_name) do
      true -> {:ok, rules}
      false -> {:error, :username_taken}
    end
  end

  def check(%Rules{stage: :choosing_teams} = _rules, { :choose_team, _team, _team_counts = [2, 2] }) do
    {:error, :teams_full}
  end

  def check(%Rules{stage: :choosing_teams} = rules, { :choose_team, team, team_counts}) do
    case Enum.at(team_counts, team - 1) do
      count when count < 2 -> {:ok, rules}
      2 -> {:error, :team_full}
    end
  end

  def check(%Rules{stage: :choosing_teams} = rules, { :confirm_teams, _team_counts = [2, 2] }) do
    {:ok, %Rules{ rules | stage: :call_or_pass }}
  end

  def check(%Rules{stage: :choosing_teams} = _rules, { :confirm_teams, _team_counts }) do
    {:error, :teams_not_filled}
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

  defp username_taken?(players, player_name) do
    Enum.member?(Keyword.keys(players), player_name)
  end

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
