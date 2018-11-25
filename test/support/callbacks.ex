defmodule Test.Callbacks do
  @moduledoc false

  defmodule CoreCallbacks do
    @moduledoc false

    @behaviour Gossip.Client.Core

    def start_agent() do
      Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    @impl true
    def user_agent(), do: "Test Client"

    @impl true
    def channels(), do: []

    @impl true
    def players(), do: []

    @impl true
    def authenticated(), do: :ok

    @impl true
    def message_broadcast(message) do
      start_agent()
      Agent.update(__MODULE__, fn state ->
        broadcasts = Map.get(state, :broadcasts, [])
        broadcasts = [message | broadcasts]
        Map.put(state, :broadcasts, broadcasts)
      end)
    end

    def broadcasts() do
      start_agent()
      Agent.get(__MODULE__, fn state ->
        Map.get(state, :broadcasts)
      end)
    end
  end

  defmodule PlayerCallbacks do
    @moduledoc false

    @behaviour Gossip.Client.Players

    def start_agent() do
      Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    @impl true
    def player_sign_in(game, player) do
      start_agent()
      Agent.update(__MODULE__, fn state ->
        sign_ins = Map.get(state, :sign_ins, [])
        sign_ins = [{game, player} | sign_ins]
        Map.put(state, :sign_ins, sign_ins)
      end)
    end

    @impl true
    def player_sign_out(game, player) do
      start_agent()
      Agent.update(__MODULE__, fn state ->
        sign_outs = Map.get(state, :sign_outs, [])
        sign_outs = [{game, player} | sign_outs]
        Map.put(state, :sign_outs, sign_outs)
      end)
    end

    @impl true
    def player_update(game, player_list) do
      start_agent()
      Agent.update(__MODULE__, fn state ->
        player_updates = Map.get(state, :player_updates, [])
        player_updates = [{game, player_list} | player_updates]
        Map.put(state, :player_updates, player_updates)
      end)
    end

    def sign_ins() do
      start_agent()
      Agent.get(__MODULE__, fn state ->
        Map.get(state, :sign_ins)
      end)
    end

    def sign_outs() do
      start_agent()
      Agent.get(__MODULE__, fn state ->
        Map.get(state, :sign_outs)
      end)
    end

    def player_updates() do
      start_agent()
      Agent.get(__MODULE__, fn state ->
        Map.get(state, :player_updates)
      end)
    end
  end

  defmodule TellCallbacks do
    @moduledoc false

    @behaviour Gossip.Client.Tells

    def start_agent() do
      Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    @impl true
    def tell_receive(from_game, from_player, to_player, message) do
      start_agent()
      Agent.update(__MODULE__, fn state ->
        receives = Map.get(state, :receives, [])
        receives = [{from_game, from_player, to_player, message} | receives]
        Map.put(state, :receives, receives)
      end)
    end

    def receives() do
      start_agent()
      Agent.get(__MODULE__, fn state ->
        Map.get(state, :receives)
      end)
    end
  end

  defmodule GameCallbacks do
    @moduledoc false

    @behaviour Gossip.Client.Games

    def start_agent() do
      Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    @impl true
    def game_connect(game) do
      start_agent()
      Agent.update(__MODULE__, fn state ->
        connects = Map.get(state, :connects, [])
        connects = [game | connects]
        Map.put(state, :connects, connects)
      end)
    end

    @impl true
    def game_disconnect(game) do
      start_agent()
      Agent.update(__MODULE__, fn state ->
        disconnects = Map.get(state, :disconnects, [])
        disconnects = [game | disconnects]
        Map.put(state, :disconnects, disconnects)
      end)
    end

    @impl true
    def game_update(game) do
      start_agent()
      Agent.update(__MODULE__, fn state ->
        game_updates = Map.get(state, :game_updates, [])
        game_updates = [game | game_updates]
        Map.put(state, :game_updates, game_updates)
      end)
    end

    def connects() do
      start_agent()
      Agent.get(__MODULE__, fn state ->
        Map.get(state, :connects)
      end)
    end

    def disconnects() do
      start_agent()
      Agent.get(__MODULE__, fn state ->
        Map.get(state, :disconnects)
      end)
    end

    def game_updates() do
      start_agent()
      Agent.get(__MODULE__, fn state ->
        Map.get(state, :game_updates)
      end)
    end
  end
end
