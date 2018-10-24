defmodule Gossip.Socket.Games do
  @moduledoc """
  "games" flag functions
  """

  require Logger

  alias Gossip.Games

  @doc false
  def games_module(), do: Application.get_env(:gossip, :callback_modules)[:games]

  @doc false
  def handle_cast({:status}, state) do
    status(state)
  end

  @doc false
  def handle_receive(state, message = %{"event" => "games/connect"}) do
    process_connect(state, message)
  end

  def handle_receive(state, message = %{"event" => "games/disconnect"}) do
    process_disconnect(state, message)
  end

  def handle_receive(state, message = %{"event" => "games/status"}) do
    process_status(state, message)
  end

  @doc """
  Process a "games/connect" event from the server
  """
  def process_connect(state, %{"payload" => payload}) do
    name = Map.get(payload, "game")
    Gossip.Games.touch_game(name)
    games_module().game_connect(name)
    {:ok, state}
  end

  @doc """
  Process a "games/disconnect" event from the server
  """
  def process_disconnect(state, %{"payload" => payload}) do
    name = Map.get(payload, "game")
    games_module().game_disconnect(name)
    {:ok, state}
  end

  @doc """
  Process a "games/status" event from the server

  If no payload is found, this was requested from a single game update
  and should have a ref, pass along to the `Games` module where it's waiting
  for the response.
  """
  def process_status(state, message = %{"payload" => payload}) do
    Logger.debug("Received games/status", type: :gossip)
    Games.response_status(message)
    games_module().game_update(payload)
    {:ok, state}
  end

  def process_status(state, message) do
    Logger.debug("Received games/status", type: :gossip)
    Games.response_status(message)
    {:ok, state}
  end

  @doc """
  Generate a "games/status" event
  """
  def status(state) do
    message = %{
      "event" => "games/status",
      "ref" => UUID.uuid4()
    }

    {:reply, message, state}
  end
end
