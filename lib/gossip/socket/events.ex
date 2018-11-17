defmodule Gossip.Socket.Events do
  @moduledoc false

  require Logger

  alias Gossip.Socket.Core
  alias Gossip.Socket.Games
  alias Gossip.Socket.Players
  alias Gossip.Socket.Tells

  @doc """
  Parse and process an event from the server

  Splits out to the sub-modules based on the kind of event
  """
  def receive(state, message) do
    with {:ok, message} <- Poison.decode(message),
         {:ok, state} <- process(state, message) do
      {:ok, state}
    else
      :stop ->
        :stop

      {:reply, message, state} ->
        {:reply, message, state}

      _ ->
        {:ok, state}
    end
  end

  @doc """
  Process an incoming event after it has been parsed

  "Routes" it to the appropriate submodule
  """
  def process(state, message = %{"event" => "authenticate"}) do
    Core.handle_receive(state, message)
  end

  def process(state, message = %{"event" => "heartbeat"}) do
    Core.handle_receive(state, message)
  end

  def process(state, message = %{"event" => "restart"}) do
    Core.handle_receive(state, message)
  end

  def process(state, message = %{"event" => "channels/" <> _}) do
    Core.handle_receive(state, message)
  end

  def process(state, message = %{"event" => "players/" <> _}) do
    Players.handle_receive(state, message)
  end

  def process(state, message = %{"event" => "tells/" <> _}) do
    Tells.handle_receive(state, message)
  end

  def process(state, message = %{"event" => "games/" <> _}) do
    Games.handle_receive(state, message)
  end

  def process(state, message) do
    Logger.debug(fn ->
      "Received unknown event - #{inspect(message)}"
    end)

    maybe_system_process(state, message)
  end

  defp maybe_system_process(state, event) do
    case Map.get(state.modules, :system) do
      nil ->
        {:ok, state}

      system_module ->
        system_module.process(state, event)
    end
  end
end
