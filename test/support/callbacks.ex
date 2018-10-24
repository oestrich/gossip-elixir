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
end
