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

  def check(%Rules{stage: :call_or_pass} = rules, :pass) do
    {:ok, rules}
  end

  def check(%Rules{stage: :call_or_pass} = rules, :calling) do
    {:ok, %{ rules | stage: :waiting_for_first_card }}
  end

  def check(%Rules{stage: :call_or_pass} = rules, :loaner) do
    {:ok, %{ rules | stage: :playing_loaner }}
  end

  def check(%Rules{stage: :waiting_for_first_card} = rules, :play_first_card) do
    {:ok, %{ rules | stage: :waiting_for_trump }}
  end

  def check(%Rules{stage: :waiting_for_trump} = rules, :call_trump) do
    {:ok, %{ rules | stage: :playing_hand }}
  end

  def check(_state, _action), do: :error

  # helpers
end
