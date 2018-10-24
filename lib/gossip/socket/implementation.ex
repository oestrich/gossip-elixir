defmodule Gossip.Socket.Implementation do
  @moduledoc false

  require Logger

  alias Gossip.Socket.Core
  alias Gossip.Socket.Games
  alias Gossip.Socket.Players
  alias Gossip.Tells

  def modules(), do: Application.get_env(:gossip, :callback_modules)
  def tells_module(), do: modules()[:tells]
  def games_module(), do: modules()[:games]
  def system_module(), do: modules()[:system]

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

  def process(state, message = %{"event" => "games/" <> _}) do
    Games.handle_receive(state, message)
  end

  def process(state, event = %{"event" => "tells/send"}) do
    Logger.debug("Received tells/send", type: :gossip)
    Tells.response(event)
    {:ok, state}
  end

  def process(state, event = %{"event" => "tells/receive", "payload" => payload}) do
    Logger.debug(fn ->
      "Received tells/receive - #{inspect(event)}"
    end, type: :gossip)

    from_game = Map.get(payload, "from_game")
    from_player = Map.get(payload, "from_name")
    to_player = Map.get(payload, "to_name")
    message = Map.get(payload, "message")

    tells_module().tell_received(from_game, from_player, to_player, message)

    {:ok, state}
  end

  def process(state, event) do
    Logger.debug(fn ->
      "Received unknown event - #{inspect(event)}"
    end)

    maybe_system_process(state, event)
  end

  defp maybe_system_process(state, event) do
    case system_module() do
      nil ->
        {:ok, state}

      system_module ->
        system_module.process(state, event)
    end
  end
end
