defmodule Gossip.Socket.GamesTest do
  use ExUnit.Case

  alias Gossip.Socket.Games
  alias Test.Callbacks.GameCallbacks

  describe "games status" do
    test "generates the event" do
      {:reply, message, _state} = Games.status(%{})

      assert message["event"] == "games/status"
      assert message["ref"]
    end

    test "generates the event for a specific game" do
      {:reply, message, _state} = Games.status(%{}, "remote ref", "ExVenture")

      assert message["event"] == "games/status"
      assert message["ref"]
      assert message["payload"]["game"] == "ExVenture"
    end
  end

  describe "process an incoming games/connect event" do
    test "sends to the games callback" do
      payload = %{"game" => "ExVenture"}

      {:ok, _state} = Games.process_connect(%{}, %{"payload" => payload})

      assert ["ExVenture"] = GameCallbacks.connects()
    end

    test "handle receive" do
      payload = %{"game" => "ExVenture"}

      {:ok, _state} = Games.handle_receive(%{}, %{"event" => "games/connect", "payload" => payload})
    end
  end

  describe "process an incoming games/disconnect event" do
    test "sends to the games callback" do
      payload = %{"game" => "ExVenture"}

      {:ok, _state} = Games.process_disconnect(%{}, %{"payload" => payload})

      assert ["ExVenture"] = GameCallbacks.disconnects()
    end

    test "handle receive" do
      payload = %{"game" => "ExVenture"}

      {:ok, _state} = Games.handle_receive(%{}, %{"event" => "games/disconnect", "payload" => payload})
    end
  end

  describe "process an incoming games/status event" do
    test "sends to the games callback" do
      payload = %{"game" => "ExVenture"}

      {:ok, _state} = Games.process_status(%{}, %{"payload" => payload})

      assert [%{"game" => "ExVenture"}] = GameCallbacks.game_updates()
    end

    test "missing a payload - when requesting a single game and that failed" do
      {:ok, _state} = Games.process_status(%{}, %{})
    end

    test "handle receive" do
      payload = %{"game" => "ExVenture"}

      {:ok, _state} = Games.handle_receive(%{}, %{"event" => "games/status", "payload" => payload})
    end
  end
end
