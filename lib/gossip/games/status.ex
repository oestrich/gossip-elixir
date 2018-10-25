defmodule Gossip.Games.Status do
  @moduledoc """
  Request and response for fetching a remote game

  Handles GenServer ref and remote refs to process a local call
  """

  require Logger

  alias Gossip.Games.Implementation

  @doc """
  Start to fetch a remote game from Gossip

  Sends a "games/status" event with the game as the payload
  """
  def request(state, ref, game_name) do
    maybe_send(state, fn ->
      send_to_gossip(state, ref, game_name)
    end)
  end

  defp maybe_send(state, fun) do
    case Process.whereis(Gossip.Socket) do
      nil ->
        {:ok, state}

      _pid ->
        fun.()
    end
  end

  defp send_to_gossip(state, ref, game_name) do
    remote_ref = UUID.uuid4()

    Logger.debug(fn ->
      "Requesting a game - ref: #{remote_ref}"
    end)

    WebSockex.cast(Gossip.Socket, {:games, {:status, remote_ref, game_name}})

    state = %{state | refs: Map.put(state.refs, remote_ref, ref)}

    {:ok, state}
  end

  @doc """
  Handle a response back from Gossip

  If the remote reference is known, reply back to the waiting call.
  """
  def response(state, event) do
    {:ok, state} = maybe_update_game(state, event)

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

  defp maybe_update_game(state, event) do
    payload = Map.get(event, "payload", %{})

    case Map.has_key?(payload, "game") do
      true ->
        Implementation.update_game(state, payload)

      false ->
        {:ok, state}
    end
  end
end
