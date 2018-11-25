defmodule Gossip.Client do
  @moduledoc """
  Behaviour for integrating Gossip into your game
  """

  defmodule Core do
    @moduledoc """
    Callbacks for the "channels" flag

    This is the only _required_ module.
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

    Used in the heartbeat
    """
    @callback players() :: [Gossip.player_name()]

    @doc """
    A callback to know when the socket is authenticated
    """
    @callback authenticated() :: :ok

    @doc """
    A new message was received from Gossip on a channel
    """
    @callback message_broadcast(Gossip.message()) :: :ok
  end

  defmodule Players do
    @moduledoc """
    Callbacks for the "players" flag
    """

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
    @callback player_update(Gossip.game_name(), [Gossip.player_name()]) :: :ok
  end

  defmodule Tells do
    @moduledoc """
    Callbacks for the "tells" flag
    """

    @doc """
    New tell received
    """
    @callback tell_receive(Gossip.game_name(), from_player :: Gossip.player_name(), to_player :: Gossip.player_name(), Gossip.message()) :: :ok
  end

  defmodule Games do
    @moduledoc """
    Callbacks for the "games" flag
    """

    @doc """
    Game status update
    """
    @callback game_update(Gossip.game()) :: :ok

    @doc """
    A game connected
    """
    @callback game_connect(Gossip.game_name()) :: :ok

    @doc """
    A game disconnected
    """
    @callback game_disconnect(Gossip.game_name()) :: :ok
  end

  defmodule SystemCallback do
    @moduledoc """
    A behavior for system level callbacks
    """

    @type state :: map()
    @type event :: map()

    @callback process(state(), event()) :: :ok
  end
end
