defmodule Gossip.Players.Implementation do
  @moduledoc false

  require Logger

  alias Gossip.Games
  alias Gossip.Players.Status

  # get a game from the map, defaulting if not present
  defp get_game(state, game_name) do
    Map.get(state.games, game_name, %{name: game_name, last_seen: Timex.now()})
  end

  defp touch_game(game) do
    Map.put(game, :last_seen, Timex.now())
  end

  @doc """
  Fetch the local cache of players
  """
  def who(state) do
    games =
      state.games
      |> Enum.into(%{}, fn {game_name, game} ->
        {game_name, Map.get(game, :players, [])}
      end)

    {:ok, games}
  end

  @doc false
  def player_list(state, game_name, players) do
    game = get_game(state, game_name)
    game =
      game
      |> Map.put(:players, players)
      |> touch_game()

    Games.Internal.touch_game(game_name)

    games = Map.put(state.games, game_name, game)
    {:ok, %{state | games: games}}
  end

  @doc """
  Add a remote player to the local cache
  """
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

  @doc """
  Remove a remote player from the local cache
  """
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

  @doc """
  Handle a response back from Gossip

  If the remote reference is known, reply back to the waiting call.
  """
  def handle_response(state, event = %{"event" => "players/status"}) do
    Status.response(state, event)
  end

  def handle_response(state, _event), do: {:ok, state}

  @doc """
  Sweep the player lists for games that are out of date
  """
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
