defmodule Gossip.Games.Implementation do
  @moduledoc false

  require Logger

  alias Gossip.Games.Internal
  alias Gossip.Games.Status

  @doc """
  Get a list of games from state
  """
  def list(state) do
    {:ok, Map.values(state.games)}
  end

  @doc """
  Update the local cache for the game
  """
  def update_game(state, game) do
    touch_game(state, game["game"])

    games = Map.put(state.games, game["game"], game)
    {:ok, %{state | games: games}}
  end

  @doc """
  Touch a game in the ETS cache for online tracking
  """
  def touch_game(state, game_name) do
    :ets.insert(Internal.ets_key(), {game_name, Timex.now()})
    {:ok, state}
  end

  @doc """
  Handle a response back from Gossip

  If the remote reference is known, reply back to the waiting call.
  """
  def handle_response(state, event = %{"event" => "games/status"}) do
    Status.response(state, event)
  end

  def handle_response(state, _event), do: {:ok, state}
end
