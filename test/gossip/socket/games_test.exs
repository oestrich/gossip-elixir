defmodule Gossip.Socket.GamesTest do
  use ExUnit.Case

  alias Gossip.Socket.Games
  alias Test.Callbacks.GameCallbacks

  setup [:with_state]

  describe "games status" do
    test "generates the event", %{state: state} do
      {:reply, message, _state} = Games.status(state)

      assert message["event"] == "games/status"
      assert message["ref"]
    end

    test "generates the event for a specific game", %{state: state} do
      {:reply, message, _state} = Games.status(state, "remote ref", "ExVenture")

      assert message["event"] == "games/status"
      assert message["ref"]
      assert message["payload"]["game"] == "ExVenture"
    end
  end

  describe "process an incoming games/connect event" do
    test "sends to the games callback", %{state: state} do
      payload = %{"game" => "ExVenture"}

      {:ok, _state} = Games.process_connect(state, %{"payload" => payload})

      assert ["ExVenture"] = GameCallbacks.connects()
    end

    test "handle receive", %{state: state} do
      payload = %{"game" => "ExVenture"}

      {:ok, _state} = Games.handle_receive(state, %{"event" => "games/connect", "payload" => payload})
    end
  end

  describe "process an incoming games/disconnect event" do
    test "sends to the games callback", %{state: state} do
      payload = %{"game" => "ExVenture"}

      {:ok, _state} = Games.process_disconnect(state, %{"payload" => payload})

      assert ["ExVenture"] = GameCallbacks.disconnects()
    end

    test "handle receive", %{state: state} do
      payload = %{"game" => "ExVenture"}

      {:ok, _state} = Games.handle_receive(state, %{"event" => "games/disconnect", "payload" => payload})
    end
  end

  describe "process an incoming games/status event" do
    test "sends to the games callback", %{state: state} do
      payload = %{"game" => "ExVenture"}

      {:ok, _state} = Games.process_status(state, %{"payload" => payload})

      assert [%{"game" => "ExVenture"}] = GameCallbacks.game_updates()
    end

    test "missing a payload - when requesting a single game and that failed", %{state: state} do
      {:ok, _state} = Games.process_status(state, %{})
    end

    test "handle receive", %{state: state} do
      payload = %{"game" => "ExVenture"}

      {:ok, _state} = Games.handle_receive(state, %{"event" => "games/status", "payload" => payload})
    end
  end

  def with_state(_) do
    %{state: %{modules: %{games: Test.Callbacks.GameCallbacks}}}
  end
end
