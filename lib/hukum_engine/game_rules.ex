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
    teams: %{1 => [], 2 => []}
  )

  def new(), do: %Rules{}

  def check(%Rules{stage: :waiting_for_players} = rules, :add_player) do
    rules = Map.put(rules, :player_count, rules.player_count + 1)
    case rules.player_count == 4 do
      true -> {:ok, %Rules{ rules | stage: :choosing_teams }}
      false -> {:ok, rules }
    end
  end

  def check(%Rules{stage: :choosing_teams} = rules, {:choose_team, player, team}) do
    chosen_team = Map.get(rules.teams, team)
    assigned_players = get_assigned_players(rules.teams)

    case {
      team_vacant?(chosen_team),
      final_player?(length(assigned_players)),
      player_unassigned?(assigned_players, player)
    } do
      {true, true, true} ->
        teams = Map.put(rules.teams, team, [player | rules.teams[team]])
        {:ok, %Rules{ rules | teams: teams, stage: :start_game, }}
      {true, false, true} ->
        teams = Map.put(rules.teams, team, [player | rules.teams[team]])
        {:ok, %Rules{ rules | teams: teams }}
      {_, _, false} ->
        {:error, :already_assigned}
      {false, _, _} ->
        {:error, :team_full}
    end
  end

  def check(_state, _action), do: :error

  # helpers

  defp team_vacant?(team), do: length(team) < 2

  defp final_player?(total_team_players), do: total_team_players == 3

  defp player_unassigned?(assigned_players, player) do
    Enum.member?(assigned_players, player) == false
  end

  defp get_assigned_players(teams) do
    teams[1] ++ teams[2]
  end
end
