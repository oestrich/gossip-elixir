defmodule Gossip.Tells do
  @moduledoc """
  Remote tells
  """

  alias Gossip.Tells.Process

  @doc """
  Send a remote tell
  """
  def send(sending_player, game_name, player_name, message) do
    response = GenServer.call(Process, {:tell, sending_player, game_name, player_name, message})

    case response do
      {:error, :offline} ->
        {:error, :offline}

      %{"status" => "success"} ->
        :ok

      %{"status" => "failure", "error" => error} ->
        {:error, error}
    end
  end

  @doc """
  Remote response
  """
  def response(event) do
    GenServer.cast(Process, {:response, event})
  end
end
