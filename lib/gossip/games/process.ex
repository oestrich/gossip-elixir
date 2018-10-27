defmodule Gossip.Games.Process do
  @moduledoc """
  GenServer process for tracking remote games

  See also:
  - `Gossip.Games.Internal` for calls/casts into this process
  - `Gossip.Games.Implementation` for the implementation of calls/casts
  - `Gossip.Games.Status` for the request/response for fetching a remote game
  """

  use GenServer

  alias Gossip.Games.Implementation
  alias Gossip.Games.Internal
  alias Gossip.Games.Status

  @refresh_minutes 5
  @refresh_list_diff_seconds 15

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init(_) do
    schedule_refresh_list()
    create_table()
    Process.send_after(self(), {:refresh_list}, :timer.seconds(5))
    {:ok, %{games: %{}, last_refresh: Timex.now(), refs: %{}}}
  end

  def handle_call({:reset}, _from, state) do
    {:reply, :ok, %{state | games: %{}}}
  end

  def handle_call({:list}, _from, state) do
    maybe_refresh_list(state)
    {:ok, who} = Implementation.list(state)
    {:reply, who, state}
  end

  def handle_call({:fetch_game, game_name}, ref, state) do
    {:ok, state} = Status.request(state, ref, game_name)
    {:noreply, state}
  end

  def handle_cast({:update_game, game}, state) do
    {:ok, state} = Implementation.update_game(state, game)
    {:noreply, state}
  end

  def handle_cast({:response, event}, state) do
    {:ok, state} = Implementation.handle_response(state, event)
    {:noreply, state}
  end

  def handle_cast({:touch_game, game}, state) do
    {:ok, state} = Implementation.touch_game(state, game)
    {:noreply, state}
  end

  def handle_info({:refresh_list}, state) do
    Gossip.fetch_games()
    schedule_refresh_list()
    {:noreply, %{state | last_refresh: Timex.now()}}
  end

  defp create_table() do
    :ets.new(Internal.ets_key(), [:set, :protected, :named_table])
  end

  defp maybe_refresh_list(state) do
    case Timex.diff(Timex.now(), state.last_refresh, :seconds) > @refresh_list_diff_seconds do
      true ->
        refresh_list()

      false ->
        :ok
    end
  end

  defp refresh_list() do
    send(self(), {:refresh_list})
  end

  defp schedule_refresh_list() do
    Process.send_after(self(), {:refresh_list}, :timer.minutes(@refresh_minutes))
  end
end
