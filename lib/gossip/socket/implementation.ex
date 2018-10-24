defmodule Gossip.Socket.Implementation do
  @moduledoc false

  require Logger

  alias Gossip.Games
  alias Gossip.Monitor
  alias Gossip.Message
  alias Gossip.Players
  alias Gossip.Tells

  def client_id(), do: Application.get_env(:gossip, :client_id)
  def client_secret(), do: Application.get_env(:gossip, :client_secret)

  def modules(), do: Application.get_env(:gossip, :callback_modules)
  def core_module(), do: modules()[:core]
  def players_module(), do: modules()[:players]
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

  def games_status(state) do
    message = Poison.encode!(%{
      "event" => "games/status",
      "ref" => UUID.uuid4()
    })

    {:reply, message, state}
  end

  def process(state, message = %{"event" => "authenticate"}) do
    case message do
      %{"status" => "success"} ->
        Logger.info("Authenticated against Gossip", type: :gossip)

        Gossip.request_players_online()

        {:ok, Map.put(state, :authenticated, true)}

      %{"status" => "failure"} ->
        Logger.info("Failed to authenticate against Gossip", type: :gossip)

        :stop

      _ ->
        {:ok, state}
    end
  end

  def process(state, %{"event" => "heartbeat"}) do
    Logger.debug("Gossip heartbeat", type: :gossip)

    message = Poison.encode!(%{
      "event" => "heartbeat",
      "payload" => %{
        "players" => core_module().players(),
      },
    })

    {:reply, message, state}
  end

  def process(state, %{"event" => "restart", "payload" => payload}) do
    Logger.debug("Gossip - restart incoming #{inspect(payload)}", type: :gossip)
    Monitor.restart_incoming(Map.get(payload, "downtime"))

    {:ok, state}
  end

  def process(state, %{"event" => "channels/broadcast", "payload" => payload}) do
    message = %Message{
      channel: payload["channel"],
      game: payload["game"],
      name: payload["name"],
      message: payload["message"],
    }

    core_module().message_broadcast(message)

    {:ok, state}
  end

  def process(state, %{"event" => "players/sign-in", "payload" => payload}) do
    Logger.debug("New sign in event", type: :gossip)

    game_name = Map.get(payload, "game")
    player_name = Map.get(payload, "name")

    Players.sign_in(game_name, player_name)

    players_module().player_sign_in(game_name, player_name)

    {:ok, state}
  end

  def process(state, %{"event" => "players/sign-out", "payload" => payload}) do
    Logger.debug("New sign out event", type: :gossip)

    game_name = Map.get(payload, "game")
    player_name = Map.get(payload, "name")

    Players.sign_out(game_name, player_name)

    players_module().player_sign_out(game_name, player_name)

    {:ok, state}
  end

  def process(state, event = %{"event" => "players/status", "payload" => payload}) do
    Logger.debug("Received players/status", type: :gossip)

    game_name = Map.get(payload, "game")
    player_names = Map.get(payload, "players")

    Players.receive_status(event)

    players_module().player_update(game_name, player_names)

    {:ok, state}
  end

  # This is here for failed events
  def process(state, event = %{"event" => "players/status"}) do
    Logger.debug("Received players/status", type: :gossip)
    Players.receive_status(event)
    {:ok, state}
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

  def process(state, event = %{"event" => "games/status", "payload" => payload}) do
    Logger.debug("Received games/status", type: :gossip)
    Games.response_status(event)
    games_module().game_update(payload)
    {:ok, state}
  end

  # This is here for failed events
  def process(state, event = %{"event" => "games/status"}) do
    Logger.debug("Received games/status", type: :gossip)
    Games.response_status(event)
    {:ok, state}
  end

  def process(state, %{"event" => "games/connect", "payload" => payload}) do
    name = Map.get(payload, "game")
    Games.touch_game(name)
    games_module().game_connected(name)
    {:ok, state}
  end

  def process(state, %{"event" => "games/disconnect", "payload" => payload}) do
    name = Map.get(payload, "game")
    games_module().game_disconnected(name)
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
