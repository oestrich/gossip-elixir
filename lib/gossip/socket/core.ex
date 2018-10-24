defmodule Gossip.Socket.Core do
  @moduledoc """
  Core flag functions
  """

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

  def handle_cast({:broadcast, channel, message}, state) do
    case broadcast(state, channel, message) do
      {:reply, message, state} ->
        {:reply, {:text, Poison.encode!(message)}, state}

      {:ok, state} ->
        {:ok, state}
    end
  end
end
