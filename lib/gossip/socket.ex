defmodule Gossip.Socket do
  @moduledoc """
  The websocket connection to the Gossip network
  """

  use WebSockex

  require Logger

  alias Gossip.Games
  alias Gossip.Monitor
  alias Gossip.Message
  alias Gossip.Players
  alias Gossip.Socket.Implementation
  alias Gossip.Tells

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

  def handle_cast({:broadcast, channel, message}, state) do
    case Implementation.broadcast(state, channel, message) do
      {:reply, message, state} ->
        {:reply, {:text, message}, state}

      {:ok, state} ->
        {:ok, state}
    end
  end

  def handle_cast({:player_sign_in, player_name}, state) do
    case Implementation.player_sign_in(state, player_name) do
      {:reply, message, state} ->
        {:reply, {:text, message}, state}

      {:ok, state} ->
        {:ok, state}
    end
  end

  def handle_cast({:player_sign_out, player_name}, state) do
    case Implementation.player_sign_out(state, player_name) do
      {:reply, message, state} ->
        {:reply, {:text, message}, state}

      {:ok, state} ->
        {:ok, state}
    end
  end

  def handle_cast(:players_status, state) do
    case Implementation.players_status(state) do
      {:reply, message, state} ->
        {:reply, {:text, message}, state}

      {:ok, state} ->
        {:ok, state}
    end
  end

  def handle_cast(:games_status, state) do
    case Implementation.games_status(state) do
      {:reply, message, state} ->
        {:reply, {:text, message}, state}

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
    {state, message} = Implementation.authorize(state)
    {:reply, {:text, message}, state}
  end

  defmodule Implementation do
    @moduledoc false

    require Logger

    def client_id(), do: Application.get_env(:gossip, :client_id)
    def client_secret(), do: Application.get_env(:gossip, :client_secret)
    def callback_module(), do: Application.get_env(:gossip, :callback_module)
    def system_module(), do: Application.get_env(:gossip, :system_module)

    def authorize(state) do
      channels = callback_module().channels()

      message = Poison.encode!(%{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => client_id(),
          "client_secret" => client_secret(),
          "user_agent" => callback_module().user_agent(),
          "supports" => ["channels", "players", "tells", "games"],
          "version" => "2.1.0",
          "channels" => channels,
        },
      })

      state = Map.put(state, :channels, channels)

      {state, message}
    end

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

    def broadcast(state, channel, message) do
      case channel in state.channels do
        true ->
          message = Poison.encode!(%{
            "event" => "channels/send",
            "payload" => %{
              "channel" => channel,
              "name" => message.name,
              "message" => message.message,
            },
          })

          {:reply, message, state}

        false ->
          {:ok, state}
      end
    end

    def player_sign_in(state, player_name) do
      message = Poison.encode!(%{
        "event" => "players/sign-in",
        "payload" => %{
          "name" => player_name,
        },
      })

      {:reply, message, state}
    end

    def player_sign_out(state, player_name) do
      message = Poison.encode!(%{
        "event" => "players/sign-out",
        "payload" => %{
          "name" => player_name,
        },
      })

      {:reply, message, state}
    end

    def players_status(state) do
      message = Poison.encode!(%{
        "event" => "players/status",
        "ref" => UUID.uuid4()
      })

      {:reply, message, state}
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
          "players" => callback_module().players(),
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

      callback_module().message_broadcast(message)

      {:ok, state}
    end

    def process(state, %{"event" => "players/sign-in", "payload" => payload}) do
      Logger.debug("New sign in event", type: :gossip)

      game_name = Map.get(payload, "game")
      player_name = Map.get(payload, "name")

      Players.sign_in(game_name, player_name)

      callback_module().player_sign_in(game_name, player_name)

      {:ok, state}
    end

    def process(state, %{"event" => "players/sign-out", "payload" => payload}) do
      Logger.debug("New sign out event", type: :gossip)

      game_name = Map.get(payload, "game")
      player_name = Map.get(payload, "name")

      Players.sign_out(game_name, player_name)

      callback_module().player_sign_out(game_name, player_name)

      {:ok, state}
    end

    def process(state, event = %{"event" => "players/status", "payload" => payload}) do
      Logger.debug("Received players/status", type: :gossip)

      game_name = Map.get(payload, "game")
      player_names = Map.get(payload, "players")

      Players.receive_status(event)

      callback_module().players_status(game_name, player_names)

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

      callback_module().tell_received(from_game, from_player, to_player, message)

      {:ok, state}
    end

    def process(state, event = %{"event" => "games/status", "payload" => payload}) do
      Logger.debug("Received games/status", type: :gossip)
      Games.response_status(event)
      callback_module().games_status(payload)
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
      callback_module().game_connected(name)
      {:ok, state}
    end

    def process(state, %{"event" => "games/disconnect", "payload" => payload}) do
      name = Map.get(payload, "game")
      callback_module().game_disconnected(name)
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
end
