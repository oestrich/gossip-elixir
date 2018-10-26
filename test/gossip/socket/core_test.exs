defmodule Gossip.Socket.CoreTest do
  use ExUnit.Case

  alias Gossip.Message
  alias Gossip.Socket.Core
  alias Test.Callbacks.CoreCallbacks

  setup [:with_state]

  describe "determining supports" do
    test "channels" do
      modules = %{core: Core}
      assert Core.supports(modules) == ["channels"]
    end

    test "players" do
      modules = %{players: Players}
      assert Core.supports(modules) == ["players"]
    end

    test "tells" do
      modules = %{tells: Tells}
      assert Core.supports(modules) == ["tells"]
    end

    test "games" do
      modules = %{games: Games}
      assert Core.supports(modules) == ["games"]
    end
  end

  describe "authenticate" do
    test "generates the authenticate event", %{state: state} do
      {:reply, message, state} = Core.authenticate(state)

      assert message["event"] == "authenticate"
      assert state.channels
    end
  end

  describe "broadcast a message on a channel" do
    test "creates the channels/send event", %{state: state} do
      state = Map.put(state, :channels, ["gossip"])
      message = %{name: "Player", message: "Hello"}

      {:reply, message, _state} = Core.broadcast(state, "gossip", message)

      assert message["event"] == "channels/send"
    end

    test "channel must be one you are subscribed to", %{state: state} do
      state = Map.put(state, :channels, [])
      message = %{name: "Player", message: "Hello"}

      {:ok, _state} = Core.broadcast(state, "gossip", message)
    end
  end

  describe "process an incoming authenticate event" do
    test "successful auth", %{state: state} do
      {:ok, state} = Core.process_authenticate(state, %{"status" => "success"})

      assert state.authenticated
    end

    test "failed auth", %{state: state} do
      :stop = Core.process_authenticate(state, %{"status" => "failure"})
    end

    test "handle receive", %{state: state} do
      {:ok, _state} = Core.handle_receive(state, %{"event" => "authenticate", "status" => "success"})
    end
  end

  describe "process an incoming heartbeat event" do
    test "returns a heartbeat event", %{state: state} do
      {:reply, message, _state} = Core.process_heartbeat(state)

      assert message["event"] == "heartbeat"
      assert message["payload"]["players"]
    end

    test "handle receive", %{state: state} do
      {:reply, message, _state} = Core.handle_receive(state, %{"event" => "heartbeat"})

      assert message["event"] == "heartbeat"
    end
  end

  describe "process an incoming restart event" do
    test "returns a heartbeat event", %{state: state} do
      {:ok, _state} = Core.process_restart(state, %{"payload" => %{"downtime" => 15}})
    end

    test "handle receive", %{state: state} do
      {:ok, _state} = Core.handle_receive(state, %{"event" => "restart", "payload" => %{"downtime" => 15}})
    end
  end

  describe "process an incoming channels/broadcast event" do
    test "sends to the core callback", %{state: state} do
      payload = %{
        "channel" => "gossip",
        "game" => "ExVenture",
        "name" => "Player",
        "message" => "Hello",
      }

      {:ok, _state} = Core.process_channel_broadcast(state, %{"payload" => payload})

      assert [%Message{channel: "gossip"}] = CoreCallbacks.broadcasts()
    end

    test "handle receive", %{state: state} do
      payload = %{
        "channel" => "gossip",
        "game" => "ExVenture",
        "name" => "Player",
        "message" => "Hello",
      }

      {:ok, _state} = Core.handle_receive(state, %{"event" => "channels/broadcast", "payload" => payload})
    end
  end

  def with_state(_) do
    %{state: %{modules: %{core: Test.Callbacks.CoreCallbacks}}}
  end
end
