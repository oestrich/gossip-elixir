defmodule Gossip.Players.Process do
  @moduledoc """
  Track remote players as they sign in and out on Gossip
  """

  use GenServer

  alias Gossip.Players.Implementation
  alias Gossip.Players.Status

  @refresh_minutes 1

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init(_) do
    schedule_refresh_list()
    {:ok, %{games: %{}, refs: %{}}}
  end

  def handle_call({:fetch_game, game_name}, ref, state) do
    {:ok, state} = Status.request(state, ref, game_name)
    {:noreply, state}
  end

  def handle_call({:reset}, _from, state) do
    {:reply, :ok, %{state | games: %{}}}
  end

  def handle_call({:who}, _from, state) do
    {:ok, who} = Implementation.who(state)
    {:reply, who, state}
  end

  def handle_cast({:player_list, game_name, players}, state) do
    {:ok, state} = Implementation.player_list(state, game_name, players)
    {:noreply, state}
  end

  def handle_cast({:response, event}, state) do
    {:ok, state} = Implementation.handle_response(state, event)
    {:noreply, state}
  end

  def handle_cast({:sign_in, game_name, player_name}, state) do
    {:ok, state} = Implementation.sign_in(state, game_name, player_name)
    {:noreply, state}
  end

  def handle_cast({:sign_out, game_name, player_name}, state) do
    {:ok, state} = Implementation.sign_out(state, game_name, player_name)
    {:noreply, state}
  end

  def handle_info({:refresh_list}, state) do
    Gossip.fetch_players()
    schedule_refresh_list()
    {:ok, state} = Implementation.sweep_games(state)
    {:noreply, state}
  end

  defp schedule_refresh_list() do
    Process.send_after(self(), {:refresh_list}, :timer.minutes(@refresh_minutes))
  end
end
