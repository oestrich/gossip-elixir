defmodule Gossip.Tells.Implementation do
  @moduledoc """
  Internals of the Tells process
  """

  alias Gossip.Tells.Send

  @doc """
  Handle a response back from Gossip

  If the remote reference is known, reply back to the waiting call.
  """
  def handle_response(state, event = %{"event" => "tells/send"}) do
    Send.response(state, event)
  end

  def handle_response(state, _event), do: {:ok, state}
end
