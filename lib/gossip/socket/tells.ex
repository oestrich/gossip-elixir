defmodule Gossip.Socket.Tells do
  @moduledoc """
  "tells" flag functions
  """

  require Logger

  alias Gossip.Tells

  def tells_module(state), do: state.modules.tells

  @doc false
  def handle_cast({:send, remote_ref, message}, state) do
    send_message(state, remote_ref, message)
  end

  @doc false
  def handle_receive(state, message = %{"event" => "tells/receive"}) do
    Telemetry.execute([:gossip, :events, :tells, :receive], 1, %{ref: message["ref"]})
    process_receive(state, message)
  end

  def handle_receive(state, message = %{"event" => "tells/send"}) do
    Telemetry.execute([:gossip, :events, :tells, :send, :response], 1, %{ref: message["ref"]})
    process_send(state, message)
  end

  @doc """
  Process a "tells/receive" event from the server
  """
  def process_receive(state, %{"payload" => payload}) do
    Logger.debug("Received tells/receive", type: :gossip)

    from_game = Map.get(payload, "from_game")
    from_player = Map.get(payload, "from_name")
    to_player = Map.get(payload, "to_name")
    message = Map.get(payload, "message")

    tells_module(state).tell_receive(from_game, from_player, to_player, message)

    {:ok, state}
  end

  @doc """
  Process a "tells/send" event from the server

  This event is simply an ACK back from the server saying it was successful
  or not, and gets forwarded straight to the waiting `Tells` server.
  """
  def process_send(state, message) do
    Logger.debug("Received tells/send", type: :gossip)
    Tells.response(message)
    {:ok, state}
  end

  @doc """
  Generate a "tells/send" event for a tell

  remote_ref is being tracked in the `Tells` process
  """
  def send_message(state, remote_ref, message) do
    message = %{
      "event" => "tells/send",
      "ref" => remote_ref,
      "payload" => %{
        "from_name" => message.sending_player,
        "to_game" => message.game_name,
        "to_name" => message.player_name,
        "sent_at" => Timex.now() |> Timex.set(microsecond: {0, 0}) |> Timex.format!("{ISO:Extended:Z}"),
        "message" => message.message
      }
    }

    {:reply, message, state}
  end
end
