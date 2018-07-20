defmodule Gossip.Tells do
  use GenServer

  require Logger

  alias Gossip.Tells.Implementation

  def response(event) do
    GenServer.cast(__MODULE__, {:response, event})
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{refs: %{}}}
  end

  def handle_call({:tell, sending_player, game_name, player_name, message}, ref, state) do
    message = %{
      sending_player: sending_player,
      game_name: game_name,
      player_name: player_name,
      message: message,
    }

    Implementation.handle_send(state, ref, message)
  end

  def handle_cast({:response, event}, state) do
    {:ok, state} = Implementation.handle_response(state, event)
    {:noreply, state}
  end

  defmodule Implementation do
    @moduledoc """
    Internals of the Tells process
    """

    @doc """
    """
    def handle_send(state, ref, message) do
      case Process.whereis(Gossip.Socket) do
        nil ->
          {:reply, {:error, :offline}, state}

        _pid ->
          send_to_gossip(state, ref, message)
      end
    end

    defp send_to_gossip(state, ref, message) do
      remote_ref = UUID.uuid4()

      Logger.debug(fn ->
        "Sending tell - ref: #{remote_ref}"
      end)

      message = %{
        "event" => "tells/send",
        "ref" => remote_ref,
        "payload" => %{
          "from" => message.sending_player,
          "game" => message.game_name,
          "player" => message.player_name,
          "sent_at" => Timex.now() |> Timex.set(microsecond: {0, 0}) |> Timex.format!("{ISO:Extended:Z}"),
          "message" => message.message
        }
      }

      WebSockex.cast(Gossip.Socket, {:send, message})

      state = %{state | refs: Map.put(state.refs, remote_ref, ref)}

      {:noreply, state}
    end

    @doc """
    Handle a response back from Gossip

    If the remote reference is known, reply back to the waiting call.
    """
    def handle_response(state, event) do
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
end
