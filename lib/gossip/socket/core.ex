defmodule Gossip.Socket.Core do
  @moduledoc """
  "channels" flag functions
  """

  require Logger

  alias Gossip.Message
  alias Gossip.Monitor

  @supports ["channels", "games", "players", "tells"]

  @doc false
  def client_id(), do: Application.get_env(:gossip, :client_id)

  @doc false
  def client_secret(), do: Application.get_env(:gossip, :client_secret)

  @doc false
  def core_module(state), do: state.modules.core

  @doc """
  Determine which support flags are available based on configured callbacks
  """
  def supports(modules) do
    modules
    |> Map.keys()
    |> Enum.map(&to_string/1)
    |> Enum.map(&replace_core/1)
    |> Enum.filter(&(&1 in @supports))
  end

  defp replace_core("core"), do: "channels"

  defp replace_core(flag), do: flag

  @doc """
  Send an authorization event
  """
  def authenticate(state) do
    :telemetry.execute([:gossip, :events, :core, :authenticate, :request], %{count: 1})

    channels = core_module(state).channels()

    message = %{
      "event" => "authenticate",
      "payload" => %{
        "client_id" => client_id(),
        "client_secret" => client_secret(),
        "user_agent" => core_module(state).user_agent(),
        "supports" => supports(state.modules),
        "version" => Gossip.gossip_version(),
        "channels" => channels,
      },
    }

    state = Map.put(state, :channels, channels)

    {:reply, message, state}
  end

  @doc """
  Subscribe to a new channel
  """
  def subscribe(state, channel) do
    :telemetry.execute([:gossip, :events, :channels, :subscribe, :request], %{count: 1})

    message = %{
      "event" => "channels/subscribe",
      "payload" => %{
        "channel" => channel,
      },
    }

    channels = Enum.uniq([channel | state.channels])
    state = %{state | channels: channels}

    {:reply, message, state}
  end

  @doc """
  Unsubscribe to a new channel
  """
  def unsubscribe(state, channel) do
    :telemetry.execute([:gossip, :events, :channels, :unsubscribe, :request], %{count: 1})

    message = %{
      "event" => "channels/unsubscribe",
      "payload" => %{
        "channel" => channel,
      },
    }

    channels = Enum.reject(state.channels, &(&1 == channel))
    state = %{state | channels: channels}

    {:reply, message, state}
  end

  @doc """
  Broadcast a new message
  """
  def broadcast(state, channel, message) do
    :telemetry.execute([:gossip, :events, :channels, :send, :request], %{count: 1})

    case channel in state.channels do
      true ->
        message = %{
          "event" => "channels/send",
          "payload" => %{
            "channel" => channel,
            "name" => message.name,
            "message" => message.message,
          },
        }

        {:reply, message, state}

      false ->
        {:ok, state}
    end
  end

  @doc false
  def handle_cast({:broadcast, channel, message}, state) do
    broadcast(state, channel, message)
  end

  def handle_cast({:subscribe, channel}, state) do
    subscribe(state, channel)
  end

  def handle_cast({:unsubscribe, channel}, state) do
    unsubscribe(state, channel)
  end

  @doc false
  def handle_receive(state, message = %{"event" => "authenticate"}) do
    :telemetry.execute([:gossip, :events, :core, :authenticate, :response], %{count: 1}, %{ref: message["ref"]})
    process_authenticate(state, message)
  end

  def handle_receive(state, %{"event" => "heartbeat"}) do
    :telemetry.execute([:gossip, :events, :core, :heartbeat, :request], %{count: 1})
    process_heartbeat(state)
  end

  def handle_receive(state, message = %{"event" => "restart"}) do
    :telemetry.execute([:gossip, :events, :core, :restart], %{count: 1}, %{ref: message["ref"]})
    process_restart(state, message)
  end

  def handle_receive(state, message = %{"event" => "channels/broadcast"}) do
    :telemetry.execute([:gossip, :events, :channels, :broadcast], %{count: 1}, %{ref: message["ref"]})
    process_channel_broadcast(state, message)
  end

  @doc """
  Process an "authenticate" event from the server
  """
  def process_authenticate(state, message) do
    case message do
      %{"status" => "success"} ->
        Logger.info("Authenticated against Gossip", type: :gossip)
        Gossip.fetch_players()
        core_module(state).authenticated()
        {:ok, state} = maybe_system_authenticated(state)
        {:ok, Map.put(state, :authenticated, true)}

      %{"status" => "failure"} ->
        Logger.info("Failed to authenticate against Gossip", type: :gossip)
        :stop

      _ ->
        {:ok, state}
    end
  end

  @doc """
  Process a "channels/broadcast" event from the server
  """
  def process_channel_broadcast(state, %{"payload" => payload}) do
    message = %Message{
      channel: payload["channel"],
      game: payload["game"],
      name: payload["name"],
      message: payload["message"],
    }

    core_module(state).message_broadcast(message)

    {:ok, state}
  end

  @doc """
  Process a "heartbeat" event from the server
  """
  def process_heartbeat(state) do
    Logger.debug("Gossip heartbeat", type: :gossip)

    message = %{
      "event" => "heartbeat",
      "payload" => %{
        "players" => core_module(state).players(),
      },
    }

    {:reply, message, state}
  end

  @doc """
  Process a "restart" event from the server
  """
  def process_restart(state, %{"payload" => payload}) do
    Logger.info("Gossip - restart incoming", type: :gossip)
    Monitor.restart_incoming(Map.get(payload, "downtime"))
    {:ok, state}
  end

  defp maybe_system_authenticated(state) do
    case Map.get(state.modules, :system) do
      nil ->
        {:ok, state}

      system_module ->
        system_module.authenticated(state)
    end
  end
end
