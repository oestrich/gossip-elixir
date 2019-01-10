defmodule Gossip.Socket.Players do
  @moduledoc """
  "players" flag functions
  """

  require Logger

  alias Gossip.Players

  @doc false
  def players_module(state), do: state.modules.players

  @doc false
  def handle_cast({:sign_in, player_name}, state) do
    sign_in(state, player_name)
  end

  def handle_cast({:sign_out, player_name}, state) do
    sign_out(state, player_name)
  end

  def handle_cast({:status}, state) do
    status(state)
  end

  @doc false
  def handle_receive(state, message = %{"event" => "players/sign-in"}) do
    :telemetry.execute([:gossip, :events, :players, :sign_in], 1, %{ref: message["ref"]})
    process_sign_in(state, message)
  end

  def handle_receive(state, message = %{"event" => "players/sign-out"}) do
    :telemetry.execute([:gossip, :events, :players, :sign_out], 1, %{ref: message["ref"]})
    process_sign_out(state, message)
  end

  def handle_receive(state, message = %{"event" => "players/status"}) do
    :telemetry.execute([:gossip, :events, :players, :status, :response], 1, %{ref: message["ref"]})
    process_status(state, message)
  end

  @doc """
  Process a "players/sign-in" event from the server
  """
  def process_sign_in(state, %{"payload" => payload}) do
    Logger.debug("New sign in event", type: :gossip)

    game_name = Map.get(payload, "game")
    player_name = Map.get(payload, "name")

    Players.Internal.sign_in(game_name, player_name)
    players_module(state).player_sign_in(game_name, player_name)

    {:ok, state}
  end

  @doc """
  Process a "players/sign-out" event from the server
  """
  def process_sign_out(state, %{"payload" => payload}) do
    Logger.debug("New sign out event", type: :gossip)

    game_name = Map.get(payload, "game")
    player_name = Map.get(payload, "name")

    Players.Internal.sign_out(game_name, player_name)
    players_module(state).player_sign_out(game_name, player_name)

    {:ok, state}
  end

  @doc """
  Process a "players/status" event from the server

  If no payload is found, this was requested from a single game update
  and should have a ref, pass along to the `Players` module where it's waiting
  for the response.
  """
  def process_status(state, event = %{"payload" => payload}) do
    Logger.debug("Received players/status", type: :gossip)

    game_name = Map.get(payload, "game")
    player_names = Map.get(payload, "players")

    Players.Internal.response(event)
    players_module(state).player_update(game_name, player_names)

    {:ok, state}
  end

  def process_status(state, event) do
    Logger.debug("Received players/status", type: :gossip)
    Players.Internal.response(event)
    {:ok, state}
  end

  @doc """
  Generate a "players/sign-in" event
  """
  def sign_in(state, player_name) do
    message = %{
      "event" => "players/sign-in",
      "payload" => %{
        "name" => player_name,
      },
    }

    {:reply, message, state}
  end

  @doc """
  Generate a "players/sign-out" event
  """
  def sign_out(state, player_name) do
    message = %{
      "event" => "players/sign-out",
      "payload" => %{
        "name" => player_name,
      },
    }

    {:reply, message, state}
  end


  @doc """
  Generate a "players/status" event
  """
  def status(state) do
    message = %{
      "event" => "players/status",
      "ref" => UUID.uuid4()
    }

    {:reply, message, state}
  end
end
