defmodule Gossip.Socket.Games do
  @moduledoc """
  "games" flag functions
  """

  def handle_cast({:status}, state) do
    status(state)
  end

  @doc """
  Generate a "games/status" event
  """
  def status(state) do
    message = %{
      "event" => "games/status",
      "ref" => UUID.uuid4()
    }

    {:reply, message, state}
  end
end
