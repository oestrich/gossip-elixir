defmodule Gossip.Players.Status do
  @moduledoc """
  Request and response for fetching a remote game list

  Handles GenServer ref and remote refs to process a local call
  """

  require Logger

  alias Gossip.Players.Implementation
  alias Gossip.RemoteCall

  @doc """
  Start to fetch a remote player list from Gossip

  Sends a "players/status" event with the game as the payload
  """
  def request(state, ref, game_name) do
    RemoteCall.maybe_send(state, fn ->
      request_players_from_gossip(state, ref, game_name)
    end)
  end

  defp request_players_from_gossip(state, ref, game_name) do
    remote_ref = UUID.uuid4()

    Logger.debug(fn ->
      "Requesting a game's players - ref: #{remote_ref}"
    end)

    message = %{
      "event" => "players/status",
      "ref" => remote_ref,
      "payload" => %{
        "game" => game_name,
      }
    }

    WebSockex.cast(Gossip.Socket, {:send, message})

    state = %{state | refs: Map.put(state.refs, remote_ref, ref)}

    {:ok, state}
  end

  @doc """
  Handle a response back from Gossip

  If the remote reference is known, reply back to the waiting call.
  """
  def response(state, event) do
    {:ok, state} = maybe_update_game(state, event)
    RemoteCall.maybe_reply(state, event)
  end

  defp maybe_update_game(state, event) do
    payload = Map.get(event, "payload", %{})

    case Map.has_key?(payload, "game") do
      true ->
        game_name = Map.get(payload, "game")
        player_names = Map.get(payload, "players")

        Implementation.player_list(state, game_name, player_names)

      false ->
        {:ok, state}
    end
  end
end
