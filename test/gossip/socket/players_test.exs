defmodule Gossip.Socket.PlayersTest do
  use ExUnit.Case

  alias Gossip.Socket.Players

  describe "player sign in" do
    test "generates the event" do
      {:reply, message, _state} = Players.sign_in(%{}, "Player")

      assert message["event"] == "players/sign-in"
      assert message["payload"]["name"] == "Player"
    end
  end

  describe "player sign out" do
    test "generates the event" do
      {:reply, message, _state} = Players.sign_out(%{}, "Player")

      assert message["event"] == "players/sign-out"
      assert message["payload"]["name"] == "Player"
    end
  end

  describe "player status" do
    test "generates the event" do
      {:reply, message, _state} = Players.status(%{})

      assert message["event"] == "players/status"
      assert message["ref"]
    end
  end
end
