defmodule Gossip.Socket.Tells do
  @moduledoc """
  "tells" flag functions
  """

  require Logger

  alias Gossip.Tells

  def tells_module(), do: Application.get_env(:gossip, :callback_modules)[:tells]

  @doc false
  def handle_receive(state, message = %{"event" => "tells/receive"}) do
    process_receive(state, message)
  end

  def handle_receive(state, message = %{"event" => "tells/send"}) do
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

    tells_module().tell_receive(from_game, from_player, to_player, message)

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
end
