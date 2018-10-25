defmodule Gossip.Games do
  @moduledoc """
  Track remote games

  The public interface
  """

  alias Gossip.Games.Internal
  alias Gossip.Games.Process

  @type game :: map()

  @doc """
  See who is signed into remote games
  """
  @spec list() :: [game()]
  def list() do
    GenServer.call(Process, {:list})
  end

  @doc """
  Check for a game being online
  """
  @spec game_online?(Gossip.game_name()) :: boolean()
  def game_online?(game_name) do
    case :ets.lookup(Internal.ets_key(), game_name) do
      [{game_name, last_seen_at}] when is_binary(game_name) ->
        active_cutoff = Timex.now() |> Timex.shift(minutes: -2)
        Timex.after?(last_seen_at, active_cutoff)

      _ ->
        false
    end
  end
end
