defmodule Gossip.Games.Internal do
  @moduledoc """
  Internal GenServer calls/casts
  """

  alias Gossip.Games
  alias Gossip.Games.Process

  @ets_key :gossip_games

  def ets_key(), do: @ets_key

  @doc """
  Request a single game's information from Gossip
  """
  @spec fetch_game(Gossip.game_name()) :: {:ok, Games.game()} | {:error, :offline}
  def fetch_game(game_name) do
    response = GenServer.call(Process, {:fetch_game, game_name})

    case response do
      %{"payload" => payload} ->
        {:ok, payload}

      %{"status" => "failure", "error" => error} ->
        {:error, error}

      {:error, :offline} ->
        {:error, :offline}
    end
  end

  @doc """
  A response came back from the server
  """
  def response(event) do
    GenServer.cast(Process, {:response, event})
  end

  @doc """
  Update the local game list after a `games/status` event comes in
  """
  @spec update_game(Games.game()) :: :ok
  def update_game(game) do
    GenServer.cast(Process, {:update_game, game})
  end

  @doc """
  Update the last seen timestamp for a game
  """
  @spec touch_game(Gossip.game_name()) :: :ok
  def touch_game(game_name) do
    GenServer.cast(Process, {:touch_game, game_name})
  end

  @doc """
  For tests only - resets the player list state
  """
  @spec reset() :: :ok
  def reset() do
    GenServer.call(Process, {:reset})
  end
end
