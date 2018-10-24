defmodule Gossip.Socket.Players do
  @moduledoc """
  "players" flag functions
  """

  @doc false
  def handle_cast({:sign_in, player_name}, state) do
    sign_in(state, player_name)
  end

  def handle_cast({:sign_out, player_name}, state) do
    sign_out(state, player_name)
  end

  def handle_cast({:status}, state) do
    status(state)
  end

  @doc """
  Generate a "players/sign-in" event
  """
  def sign_in(state, player_name) do
    message = %{
      "event" => "players/sign-in",
      "payload" => %{
        "name" => player_name,
      },
    }

    {:reply, message, state}
  end

  @doc """
  Generate a "players/sign-out" event
  """
  def sign_out(state, player_name) do
    message = %{
      "event" => "players/sign-out",
      "payload" => %{
        "name" => player_name,
      },
    }

    {:reply, message, state}
  end


  @doc """
  Generate a "players/status" event
  """
  def status(state) do
    message = %{
      "event" => "players/status",
      "ref" => UUID.uuid4()
    }

    {:reply, message, state}
  end
end
