defmodule Gossip.Client do
  @moduledoc """
  Behaviour for integrating Gossip into your game
  """

  @doc """
  Get the game's User Agent.

  This should return the game name with a version number.
  """
  @callback user_agent() :: Gossip.user_agent()

  @doc """
  Get the channels you want to subscribe to on start
  """
  @callback channels() :: [Gossip.channel_name()]

  @doc """
  Get the current names of connected players
  """
  @callback players() :: [Gossip.player_name()]

  @doc """
  A new message was received from Gossip on a channel
  """
  @callback message_broadcast(Gossip.message()) :: :ok

  @doc """
  A player has signed in
  """
  @callback player_sign_in(Gossip.game_name(), Gossip.player_name()) :: :ok

  @doc """
  A player has signed out
  """
  @callback player_sign_out(Gossip.game_name(), Gossip.player_name()) :: :ok

  @doc """
  Player status update

  You will receive this callback anytime a `players/status` event is sent. These are sent
  after calling `Gossip.request_players_online/0` and periodically updated from the local
  player cache, `Gossip.Players`.
  """
  @callback players_status(Gossip.game_name(), [Gossip.player_name()]) :: :ok

  @doc """
  New tell received
  """
  @callback tell_received(Gossip.game_name(), from_player :: Gossip.player_name(), to_player :: Gossip.player_name(), Gossip.message()) :: :ok

  @doc """
  Game status update
  """
  @since "0.6.0"
  @callback games_status(Gossip.game()) :: :ok

  @doc """
  A game connected
  """
  @since "0.6.1"
  @callback game_connected(Gossip.game_name()) :: :ok

  @doc """
  A game disconnected
  """
  @since "0.6.1"
  @callback game_disconnected(Gossip.game_name()) :: :ok

  defmodule SystemCallback do
    @moduledoc """
    A behavior for system level callbacks
    """

    @type state :: map()
    @type event :: map()

    @callback process(state(), event()) :: :ok
  end
end
