defmodule HukumEngine.Rules do
  @behaviour :gen_statem

  alias HukumEngine.Rules

  defstruct(
    player_count: 0
  )

  # Client API

  def start_link() do
    :gen_statem.start_link(__MODULE__, [], [])
  end

  def add_player(fsm) do
    :gen_statem.call(fsm, :add_player)
  end

  # mandatory callbacks

  def init([]), do: {:ok, :waiting_for_players, %Rules{}}

  def callback_mode(), do: :state_functions

  def terminate(_reason, _state, _data), do: :void

  def code_change(_vsn, state, data, _extra), do: {:ok, state, data}

  # state functions

  def waiting_for_players({:call, from}, :add_player, state) do
    case state.player_count do
      3 ->
        new_state = increment_player_count(state)
        { :next_state, :playing, new_state, {:reply, from, :players_ready }}
      count when count < 3 ->
        new_state = increment_player_count(state)
        { :keep_state, new_state, {:reply, from, :ok }}
      count when count > 3 ->
        { :keep_state_and_data, {:reply, from, :error }}
    end
  end

  def playing({:call, from}, _, _state) do
    { :keep_state_and_data, {:reply, from, :error }}
  end

  # helpers

  defp increment_player_count(state) do
    %{ state | player_count: state.player_count + 1}
  end

end
