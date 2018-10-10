defmodule Gossip.Games do
  @moduledoc """
  Track remote players as they sign in and out on Gossip
  """

  use GenServer

  alias Gossip.Games.Implementation

  @type game :: map()

  @refresh_minutes 5
  @refresh_list_diff_seconds 15

  @doc """
  See who is signed into remote games
  """
  @spec list() :: [game()]
  def list() do
    GenServer.call(__MODULE__, {:list})
  end

  @doc """
  Update the local player list after a `players/status` event comes in
  """
  @spec update_game(game()) :: :ok
  def update_game(game) do
    GenServer.cast(__MODULE__, {:update_game, game})
  end

  @doc """
  For tests only - resets the player list state
  """
  @spec reset() :: :ok
  def reset() do
    GenServer.call(__MODULE__, {:reset})
  end

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init(_) do
    schedule_refresh_list()
    Process.send_after(self(), {:refresh_list}, :timer.seconds(5))
    {:ok, %{games: %{}, last_refresh: Timex.now()}}
  end

  def handle_call({:reset}, _from, state) do
    {:reply, :ok, %{state | games: %{}}}
  end

  def handle_call({:list}, _from, state) do
    maybe_refresh_list(state)
    {:ok, who} = Implementation.list(state)
    {:reply, who, state}
  end

  def handle_cast({:update_game, game}, state) do
    {:ok, state} = Implementation.update_game(state, game)
    {:noreply, state}
  end

  def handle_info({:refresh_list}, state) do
    Gossip.request_games()
    schedule_refresh_list()
    {:noreply, %{state | last_refresh: Timex.now()}}
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

  defmodule Implementation do
    @moduledoc false

    @doc false
    def list(state) do
      {:ok, Map.values(state.games)}
    end

    @doc false
    def update_game(state, game) do
      games = Map.put(state.games, game["name"], game)

      {:ok, %{state | games: games}}
    end
  end
end
