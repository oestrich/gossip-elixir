defmodule Gossip.RemoteCall do
  @moduledoc """
  Common code for remote calls
  """

  @doc """
  If the Socket is online, call the function
  """
  def maybe_send(state, fun) do
    case Process.whereis(Gossip.Socket) do
      nil ->
        {:ok, state}

      _pid ->
        fun.()
    end
  end

  @doc """
  If the ref is known, then reply to the calling function
  """
  def maybe_reply(state, event) do
    case Map.get(state.refs, event["ref"]) do
      nil ->
        {:ok, state}

      ref ->
        GenServer.reply(ref, event)

        refs = Map.delete(state.refs, event["ref"])
        state = Map.put(state, :refs, refs)

        {:ok, state}
    end
  end
end
