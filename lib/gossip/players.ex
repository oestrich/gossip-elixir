defmodule Gossip.Players do
  @moduledoc """
  Track remote players as they sign in and out on Gossip
  """

  use GenServer

  alias Gossip.Players.Implementation

  @type who_list() :: %{
    Gossip.game_name() => [Gossip.player_name],
  }

  @refresh_minutes 1

  @doc """
  See who is signed into remote games
  """
  @spec who() :: who_list()
  def who() do
    GenServer.call(__MODULE__, {:who})
  end

  @doc """
  A player has signed into a remote game
  """
  def sign_in(game_name, player_name) do
    GenServer.cast(__MODULE__, {:sign_in, game_name, player_name})
  end

  @doc """
  A player has signed out of a remote game
  """
  def sign_out(game_name, player_name) do
    GenServer.cast(__MODULE__, {:sign_out, game_name, player_name})
  end

  @doc """
  Update the local player list after a `players/status` event comes in
  """
  @spec player_list(Gossip.game_name, [Gossip.player_name]) :: :ok
  def player_list(game_name, players) do
    GenServer.cast(__MODULE__, {:player_list, game_name, players})
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
    {:ok, %{games: %{}}}
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

  def handle_cast({:sign_in, game_name, player_name}, state) do
    {:ok, state} = Implementation.sign_in(state, game_name, player_name)
    {:noreply, state}
  end

  def handle_cast({:sign_out, game_name, player_name}, state) do
    {:ok, state} = Implementation.sign_out(state, game_name, player_name)
    {:noreply, state}
  end

  def handle_info({:refresh_list}, state) do
    Gossip.request_players_online()
    schedule_refresh_list()
    {:ok, state} = Implementation.sweep_games(state)
    {:noreply, state}
  end

  defp schedule_refresh_list() do
    Process.send_after(self(), {:refresh_list}, :timer.minutes(@refresh_minutes))
  end

  defmodule Implementation do
    @moduledoc false

    # get a game from the map, defaulting if not present
    defp get_game(state, game_name) do
      Map.get(state.games, game_name, %{last_seen: Timex.now()})
    end

    defp touch_game(game) do
      Map.put(game, :last_seen, Timex.now())
    end

    @doc false
    def who(state) do
      games =
        state.games
        |> Enum.map(fn {game_name, game} ->
          {game_name, Map.get(game, :players, [])}
        end)
        |> Enum.into(%{})

      {:ok, games}
    end

    @doc false
    def player_list(state, game_name, players) do
      game = get_game(state, game_name)
      game =
        game
        |> Map.put(:players, players)
        |> touch_game()

      games = Map.put(state.games, game_name, game)
      {:ok, %{state | games: games}}
    end

    @doc false
    def sign_in(state, game_name, player_name) do
      game = get_game(state, game_name)

      players = Map.get(game, :players, [])
      players = [player_name | players]
      players =
        players
        |> Enum.sort()
        |> Enum.uniq()

      game =
        game
        |> Map.put(:players, players)
        |> touch_game()

      games = Map.put(state.games, game_name, game)
      {:ok, %{state | games: games}}
    end

    @doc false
    def sign_out(state, game_name, player_name) do
      game = get_game(state, game_name)

      players =
        game
        |> Map.get(:players, [])
        |> List.delete(player_name)

      case Enum.empty?(players) do
        true ->
          games = Map.delete(state.games, game_name)
          {:ok, %{state | games: games}}

        false ->
          game =
            game
            |> Map.put(:players, players)
            |> touch_game()

          games = Map.put(state.games, game_name, game)
          {:ok, %{state | games: games}}
      end
    end

    @doc false
    def sweep_games(state) do
      active_cutoff = Timex.now() |> Timex.shift(minutes: -3)

      games =
        state.games
        |> Enum.reject(fn {_name, game} ->
          Timex.after?(game.last_seen, active_cutoff)
        end)
        |> Enum.into(%{})

      state = Map.put(state, :games, games)

      {:ok, state}
    end
  end
end
