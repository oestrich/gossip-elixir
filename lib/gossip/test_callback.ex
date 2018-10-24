defmodule Gossip.TestCallback do
  @moduledoc false

  defmodule Core do
    @moduledoc false

    @behaviour Gossip.Client.Core

    @impl true
    def user_agent(), do: "Test Client"

    @impl true
    def channels(), do: ["gossip"]

    @impl true
    def players(), do: []

    @impl true
    def message_broadcast(_message), do: :ok
  end

  defmodule Players do
    @moduledoc false

    @behaviour Gossip.Client.Players

    @impl true
    def player_sign_in(_game_name, _player_name), do: :ok

    @impl true
    def player_sign_out(_game_name, _player_name), do: :ok

    @impl true
    def player_update(_game_name, _player_names), do: :ok
  end

  defmodule Tells do
    @moduledoc false

    @behaviour Gossip.Client.Tells

    @impl true
    def tell_receive(_from_game, _from_player, _to_player, _message), do: :ok
  end

  defmodule Games do
    @moduledoc false

    @behaviour Gossip.Client.Games

    @impl true
    def game_update(_game), do: :ok

    @impl true
    def game_connect(_game), do: :ok

    @impl true
    def game_disconnect(_game), do: :ok
  end
end
