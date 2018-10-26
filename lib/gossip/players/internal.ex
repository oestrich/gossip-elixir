defmodule Gossip.Players.Internal do
  @moduledoc """
  Internal GenServer calls/casts
  """

  alias Gossip.Players
  alias Gossip.Players.Process

  @doc """
  Update the local player list after a `players/status` event comes in
  """
  @spec player_list(Gossip.game_name(), [Gossip.player_name()]) :: :ok
  def player_list(game_name, players) do
    GenServer.cast(Process, {:player_list, game_name, players})
  end

  @doc """
  A player has signed into a remote game
  """
  def sign_in(game_name, player_name) do
    GenServer.cast(Process, {:sign_in, game_name, player_name})
  end

  @doc """
  A player has signed out of a remote game
  """
  def sign_out(game_name, player_name) do
    GenServer.cast(Process, {:sign_out, game_name, player_name})
  end

  @doc """
  Fetch a remote player list from Gossip
  """
  @spec fetch_players(Gossip.game_name()) :: {:ok, Players.status()} | {:error, :offline}
  def fetch_players(game_name) do
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
  Receive a new "players/status" event from the Gossip socket

  This checks for local calls before maybe updating the local cache

  For internal use.
  """
  def response(event) do
    GenServer.cast(Process, {:response, event})
  end

  @doc """
  For tests only - resets the player list state
  """
  @spec reset() :: :ok
  def reset() do
    GenServer.call(Process, {:reset})
  end
end
