defmodule HukumEngine.Rules do
  alias __MODULE__

  # Finite state machine for managing the rules about state transitions in our
  # game. The stages of a game are:
  # :waiting_for_players
  # :choosing_teams
  # :call_or_pass
  # :calling
  # more tk...

  defstruct(
    stage: :waiting_for_players,
    player_count: 0,
    team_counts: %{1 => 0, 2 => 0},
    player_turn: nil
  )

  def new(), do: %Rules{}

  def check(%Rules{stage: :waiting_for_players} = rules, :add_player) do
    rules = Map.put(rules, :player_count, rules.player_count + 1)
    case rules.player_count == 4 do
      true -> {:ok, %Rules{ rules | stage: :choosing_teams }}
      false -> {:ok, rules }
    end
  end

  def check(%Rules{stage: :choosing_teams} = rules, {:choose_team, team}) do
    team_count = Map.get(rules.team_count, team)
    total = team_total(rules.team_counts)
    case { team_vacant?(team_count), final_team_player?(total) } do
      {true, true} ->
        team_counts = increment_team_counts(rules.team_counts, team)
        {:ok, %Rules{ rules | team_counts: team_counts, stage: :calling }}
      {true, false} ->
        team_counts = increment_team_counts(rules.team_counts, team)
        {:ok, %Rules{ rules | team_counts: team_counts, stage: :choosing_teams }}
      {false, _} ->
        {:error, rules}
    end
  end

  def check(_state, _action), do: :error

  # helpers

  defp team_vacant?(team_count), do: team_count < 2

  defp final_team_player?(total_team_players), do: total_team_players == 3

  defp team_total(team_counts) do
    Enum.reduce(team_counts, 0, fn({_k, count}, acc) -> count + acc end)
  end

  defp increment_team_counts(team_counts, team) do
    Map.put(team_counts, team, Map.get(team_counts, team) + 1)
  end
end
