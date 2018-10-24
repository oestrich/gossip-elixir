defmodule Gossip.Socket.CoreTest do
  use ExUnit.Case

  alias Gossip.Socket.Core

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
end
