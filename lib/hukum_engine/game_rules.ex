defmodule HukumEngine.Rules do
  alias __MODULE__
  import Kernel

  # Finite state machine for managing the rules about state transitions in our
  # game. The stages of a game are:
  # :waiting_for_teams
  # :call_or_pass
  # :calling
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


  def check(_state, _action), do: :error

  # helpers

end
