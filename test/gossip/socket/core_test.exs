defmodule Gossip.Socket.CoreTest do
  use ExUnit.Case

  alias Gossip.Message
  alias Gossip.Socket.Core
  alias Test.Callbacks.CoreCallbacks

  describe "determining supports" do
    test "channels" do
      modules = [core: Gossip.TestClient.Core]
      assert Core.supports(modules) == ["channels"]
    end

    test "players" do
      modules = [players: Players]
      assert Core.supports(modules) == ["players"]
    end

    test "tells" do
      modules = [tells: Tells]
      assert Core.supports(modules) == ["tells"]
    end

    test "games" do
      modules = [games: Games]
      assert Core.supports(modules) == ["games"]
    end
  end

  describe "authenticate" do
    test "generates the authenticate event" do
      {:reply, message, state} = Core.authenticate(%{})

      assert message["event"] == "authenticate"
      assert state.channels
    end
  end

  describe "broadcast a message on a channel" do
    test "creates the channels/send event" do
      state = %{channels: ["gossip"]}
      message = %{name: "Player", message: "Hello"}

      {:reply, message, _state} = Core.broadcast(state, "gossip", message)

      assert message["event"] == "channels/send"
    end

    test "channel must be one you are subscribed to" do
      state = %{channels: []}
      message = %{name: "Player", message: "Hello"}

      {:ok, _state} = Core.broadcast(state, "gossip", message)
    end
  end

  describe "process an incoming authenticate event" do
    test "successful auth" do
      {:ok, state} = Core.process_authenticate(%{}, %{"status" => "success"})

      assert state.authenticated
    end

    test "failed auth" do
      :stop = Core.process_authenticate(%{}, %{"status" => "failure"})
    end

    test "handle receive" do
      {:ok, _state} = Core.handle_receive(%{}, %{"event" => "authenticate", "status" => "success"})
    end
  end

  describe "process an incoming heartbeat event" do
    test "returns a heartbeat event" do
      {:reply, message, _state} = Core.process_heartbeat(%{})

      assert message["event"] == "heartbeat"
      assert message["payload"]["players"]
    end

    test "handle receive" do
      {:reply, message, _state} = Core.handle_receive(%{}, %{"event" => "heartbeat"})

      assert message["event"] == "heartbeat"
    end
  end

  describe "process an incoming restart event" do
    test "returns a heartbeat event" do
      {:ok, _state} = Core.process_restart(%{}, %{"payload" => %{"downtime" => 15}})
    end

    test "handle receive" do
      {:ok, _state} = Core.handle_receive(%{}, %{"event" => "restart", "payload" => %{"downtime" => 15}})
    end
  end

  describe "process an incoming channels/broadcast event" do
    test "sends to the core callback" do
      payload = %{
        "channel" => "gossip",
        "game" => "ExVenture",
        "name" => "Player",
        "message" => "Hello",
      }

      {:ok, _state} = Core.process_channel_broadcast(%{}, %{"payload" => payload})

      assert [%Message{channel: "gossip"}] = CoreCallbacks.broadcasts()
    end

    test "handle receive" do
      payload = %{
        "channel" => "gossip",
        "game" => "ExVenture",
        "name" => "Player",
        "message" => "Hello",
      }

      {:ok, _state} = Core.handle_receive(%{}, %{"event" => "channels/broadcast", "payload" => payload})
    end
  end
end
