defmodule Gossip.Socket.Core do
  @moduledoc """
  "channels" flag functions
  """

  require Logger

  alias Gossip.Message
  alias Gossip.Monitor

  @supports ["channels", "players", "tells", "games"]

  @doc false
  def client_id(), do: Application.get_env(:gossip, :client_id)

  @doc false
  def client_secret(), do: Application.get_env(:gossip, :client_secret)

  @doc false
  def modules(), do: Application.get_env(:gossip, :callback_modules)

  @doc false
  def core_module(), do: modules()[:core]

  @doc """
  Determine which support flags are available based on configured callbacks
  """
  def supports(modules \\ modules()) do
    modules
    |> Keyword.keys()
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
    channels = core_module().channels()

    message = %{
      "event" => "authenticate",
      "payload" => %{
        "client_id" => client_id(),
        "client_secret" => client_secret(),
        "user_agent" => core_module().user_agent(),
        "supports" => supports(),
        "version" => Gossip.gossip_version(),
        "channels" => channels,
      },
    }

    state = Map.put(state, :channels, channels)

    {:reply, message, state}
  end

  @doc """
  Broadcast a new message
  """
  def broadcast(state, channel, message) do
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

  @doc false
  def handle_receive(state, message = %{"event" => "authenticate"}) do
    process_authenticate(state, message)
  end

  def handle_receive(state, message = %{"event" => "channels/broadcast"}) do
    process_channel_broadcast(state, message)
  end

  def handle_receive(state, %{"event" => "heartbeat"}) do
    process_heartbeat(state)
  end

  def handle_receive(state, message = %{"event" => "restart"}) do
    process_restart(state, message)
  end

  @doc """
  Process an "authenticate" event from the server
  """
  def process_authenticate(state, message) do
    case message do
      %{"status" => "success"} ->
        Logger.info("Authenticated against Gossip", type: :gossip)
        Gossip.fetch_players()
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

    core_module().message_broadcast(message)

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
        "players" => core_module().players(),
      },
    }

    {:reply, message, state}
  end

  @doc """
  Process a "restart" event from the server
  """
  def process_restart(state, %{"payload" => payload}) do
    Logger.debug(fn ->
      "Gossip - restart incoming #{inspect(payload)}"
    end, type: :gossip)
    Monitor.restart_incoming(Map.get(payload, "downtime"))
    {:ok, state}
  end
end
