defmodule Gossip.Tells.Process do
  @moduledoc """
  GenServer process for remote tells

  See also:
  - `Gossip.Tells.Implementation` for the implementation of calls/casts
  - `Gossip.Tells.Send` for request/response for sending a remote tell
  """

  use GenServer

  require Logger

  alias Gossip.Tells.Implementation
  alias Gossip.Tells.Send

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

    {:ok, state} = Send.request(state, ref, message)
    {:noreply, state}
  end

  def handle_cast({:response, event}, state) do
    {:ok, state} = Implementation.handle_response(state, event)
    {:noreply, state}
  end
end
