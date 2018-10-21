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

  @doc false
  @since "0.6.0"
  @spec request_game(Gossip.game_name()) :: {:ok, game()} | {:error, :offline}
  def request_game(game_name) do
    response = GenServer.call(__MODULE__, {:fetch_game, game_name})

    case response do
      %{"payload" => payload} ->
        {:ok, payload}

      {:error, :offline} ->
        {:error, :offline}
    end
  end

  @doc false
  def response_status(event) do
    GenServer.cast(__MODULE__, {:response_status, event})
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
    Implementation.handle_fetch_game(state, ref, game_name)
  end

  def handle_cast({:update_game, game}, state) do
    {:ok, state} = Implementation.update_game(state, game)
    {:noreply, state}
  end

  def handle_cast({:response_status, event}, state) do
    {:ok, state} = Implementation.handle_response(state, event)
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

    require Logger

    @doc false
    def list(state) do
      {:ok, Map.values(state.games)}
    end

    @doc false
    def update_game(state, game) do
      games = Map.put(state.games, game["name"], game)

      {:ok, %{state | games: games}}
    end

    def handle_fetch_game(state, ref, game_name) do
      case Process.whereis(Gossip.Socket) do
        nil ->
          {:reply, {:error, :offline}, state}

        _pid ->
          send_to_gossip(state, ref, game_name)
      end
    end

    defp send_to_gossip(state, ref, game_name) do
      remote_ref = UUID.uuid4()

      Logger.debug(fn ->
        "Requesting a game - ref: #{remote_ref}"
      end)

      message = %{
        "event" => "games/status",
        "ref" => remote_ref,
        "payload" => %{
          "game" => game_name,
        }
      }

      WebSockex.cast(Gossip.Socket, {:send, message})

      state = %{state | refs: Map.put(state.refs, remote_ref, ref)}

      {:noreply, state}
    end

    @doc """
    Handle a response back from Gossip

    If the remote reference is known, reply back to the waiting call.
    """
    def handle_response(state, event) do
      {:ok, state} = maybe_update_game(state, event)

      case Map.get(state.refs, event["ref"]) do
        nil ->
          {:ok, state}

        ref ->
          GenServer.reply(ref, event)

          refs = Map.delete(state.refs, event["ref"])
          state = Map.put(state, :refs, refs)

          {:ok, state}
      end
    end

    defp maybe_update_game(state, event) do
      payload = Map.get(event, "payload", %{})

      case Map.has_key?(payload, "game") do
        true ->
          update_game(state, payload)

        false ->
          {:ok, state}
      end
    end
  end
end
