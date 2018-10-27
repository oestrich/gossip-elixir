defmodule Gossip.Players do
  @moduledoc """
  Track remote players as they sign in and out on Gossip
  """

  alias Gossip.Players.Process

  @type status :: %{}
  @type who_list :: %{
    Gossip.game_name() => [Gossip.player_name],
  }

  @doc """
  See who is signed into remote games
  """
  @spec who() :: who_list()
  def who() do
    GenServer.call(Process, {:who})
  end
end
