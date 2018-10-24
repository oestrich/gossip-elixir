defmodule Gossip.Socket do
  @moduledoc """
  The websocket connection to the Gossip network
  """

  use WebSockex

  require Logger

  alias Gossip.Monitor
  alias Gossip.Socket.Core
  alias Gossip.Socket.Implementation
  alias Gossip.Socket.Players
  alias Gossip.Socket.Games

  def url() do
    Application.get_env(:gossip, :url) || "wss://gossip.haus/socket"
  end

  def start_link() do
    state = %{
      authenticated: false,
      channels: [],
    }

    Logger.debug("Starting socket", type: :gossip)

    WebSockex.start_link(url(), __MODULE__, state, [name: Gossip.Socket])
  end

  def handle_connect(_conn, state) do
    Monitor.monitor()

    send(self(), {:authorize})
    {:ok, state}
  end

  def handle_frame({:text, message}, state) do
    case Implementation.receive(state, message) do
      {:ok, state} ->
        {:ok, state}

      {:reply, message, state} ->
        {:reply, {:text, message}, state}

      :stop ->
        Logger.info("Closing the Gossip websocket", type: :gossip)
        {:close, state}

      :error ->
        {:ok, state}
    end
  end

  def handle_frame(_frame, state) do
    {:ok, state}
  end

  def handle_cast({:core, message}, state) do
    case Core.handle_cast(message, state) do
      {:reply, message, state} ->
        {:reply, {:text, Poison.encode!(message)}, state}

      {:ok, state} ->
        {:ok, state}
    end
  end

  def handle_cast({:players, message}, state) do
    case Players.handle_cast(message, state) do
      {:reply, message, state} ->
        {:reply, {:text, Poison.encode!(message)}, state}

      {:ok, state} ->
        {:ok, state}
    end
  end

  def handle_cast({:games, message}, state) do
    case Games.handle_cast(message, state) do
      {:reply, message, state} ->
        {:reply, {:text, Poison.encode!(message)}, state}

      {:ok, state} ->
        {:ok, state}
    end
  end

  def handle_cast({:send, message}, state) do
    {:reply, {:text, Poison.encode!(message)}, state}
  end

  def handle_cast(_, state) do
    {:ok, state}
  end

  def handle_info({:authorize}, state) do
    {:reply, message, state} = Core.authenticate(state)
    {:reply, {:text, Poison.encode!(message)}, state}
  end
end
