defmodule Gossip.Socket.GamesTest do
  use ExUnit.Case

  alias Gossip.Socket.Games

  describe "games status" do
    test "generates the event" do
      {:reply, message, _state} = Games.status(%{})

      assert message["event"] == "games/status"
      assert message["ref"]
    end
  end
end
