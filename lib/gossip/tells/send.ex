defmodule Gossip.Tells.Send do
  @moduledoc """
  Request and response for sending a remote tell

  Handles GenServer ref and remote refs to process a local call
  """

  require Logger

  alias Gossip.RemoteCall

  @doc """
  If the process is online, send a tell to Gossip
  """
  def request(state, ref, message) do
    RemoteCall.maybe_send(state, fn ->
      send_to_gossip(state, ref, message)
    end)
  end

  defp send_to_gossip(state, ref, message) do
    remote_ref = UUID.uuid4()

    Logger.debug(fn ->
      "Sending tell - ref: #{remote_ref}"
    end)

    WebSockex.cast(Gossip.Socket, {:tells, {:send, remote_ref, message}})

    state = %{state | refs: Map.put(state.refs, remote_ref, ref)}

    {:ok, state}
  end

  def response(state, event) do
    RemoteCall.maybe_reply(state, event)
  end
end
