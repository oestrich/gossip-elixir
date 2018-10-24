defmodule Gossip.Socket.PlayersTest do
  use ExUnit.Case

  alias Gossip.Socket.Players
  alias Test.Callbacks.PlayerCallbacks

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

  describe "process an incoming players/sign-in event" do
    test "sends to the players callback" do
      payload = %{"game" => "ExVenture", "name" => "Player"}

      {:ok, _state} = Players.process_sign_in(%{}, %{"payload" => payload})

      assert [{"ExVenture", "Player"}] = PlayerCallbacks.sign_ins()
    end

    test "handle receive" do
      payload = %{"game" => "ExVenture", "name" => "Player"}

      {:ok, _state} = Players.handle_receive(%{}, %{"event" => "players/sign-in", "payload" => payload})
    end
  end

  describe "process an incoming players/sign-out event" do
    test "sends to the players callback" do
      payload = %{"game" => "ExVenture", "name" => "Player"}

      {:ok, _state} = Players.process_sign_out(%{}, %{"payload" => payload})

      assert [{"ExVenture", "Player"}] = PlayerCallbacks.sign_outs()
    end

    test "handle receive" do
      payload = %{"game" => "ExVenture", "name" => "Player"}

      {:ok, _state} = Players.handle_receive(%{}, %{"event" => "players/sign-out", "payload" => payload})
    end
  end

  describe "process an incoming players/status event" do
    test "sends to the players callback" do
      payload = %{"game" => "ExVenture", "players" => ["Player"]}

      {:ok, _state} = Players.process_status(%{}, %{"payload" => payload})

      assert [{"ExVenture", ["Player"]}] = PlayerCallbacks.player_updates()
    end

    test "missing a payload - when requesting a single game and that failed" do
      {:ok, _state} = Players.process_status(%{}, %{})
    end

    test "handle receive" do
      payload = %{"game" => "ExVenture", "players" => ["Player"]}

      {:ok, _state} = Players.handle_receive(%{}, %{"event" => "players/status", "payload" => payload})
    end
  end
end
