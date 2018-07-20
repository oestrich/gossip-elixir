defmodule Gossip.Tells do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def response(event) do
    GenServer.cast(__MODULE__, {:response, event})
  end

  def init(_) do
    {:ok, %{refs: %{}}}
  end

  def handle_call({:tell, sending_player, game_name, player_name, message}, ref, state) do
    case Process.whereis(Gossip.Socket) do
      nil ->
        {:reply, {:error, :offline}, state}

      _pid ->
        remote_ref = UUID.uuid4()
        Logger.debug(fn ->
          "Sending tell - ref: #{remote_ref}"
        end)

        message = %{
          "event" => "tells/send",
          "ref" => remote_ref,
          "payload" => %{
            "from" => sending_player,
            "game" => game_name,
            "player" => player_name,
            "sent_at" => Timex.now() |> Timex.set(microsecond: {0, 0}) |> Timex.format!("{ISO:Extended:Z}"),
            "message" => message
          }
        }

        WebSockex.cast(Gossip.Socket, {:send, message})

        state = %{state | refs: Map.put(state.refs, remote_ref, ref)}

        {:noreply, state}
    end
  end

  def handle_cast({:response, event}, state) do
    case Map.get(state.refs, event["ref"]) do
      nil ->
        {:noreply, state}

      ref ->
        GenServer.reply(ref, event)

        refs = Map.delete(state.refs, event["ref"])
        state = Map.put(state, :refs, refs)

        {:noreply, state}
    end
  end
end
