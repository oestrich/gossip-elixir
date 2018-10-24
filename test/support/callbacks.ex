defmodule Test.Callbacks do
  defmodule CoreCallbacks do
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
end
