defmodule Gossip.Socket.PlayersTest do
  use ExUnit.Case

  alias Gossip.Socket.Players
  alias Test.Callbacks.PlayerCallbacks

  setup [:with_state]

  describe "player sign in" do
    test "generates the event", %{state: state} do
      {:reply, message, _state} = Players.sign_in(state, "Player")

      assert message["event"] == "players/sign-in"
      assert message["payload"]["name"] == "Player"
    end
  end

  describe "player sign out" do
    test "generates the event", %{state: state} do
      {:reply, message, _state} = Players.sign_out(state, "Player")

      assert message["event"] == "players/sign-out"
      assert message["payload"]["name"] == "Player"
    end
  end

  describe "player status" do
    test "generates the event", %{state: state} do
      {:reply, message, _state} = Players.status(state)

      assert message["event"] == "players/status"
      assert message["ref"]
    end
  end

  describe "process an incoming players/sign-in event" do
    test "sends to the players callback", %{state: state} do
      payload = %{"game" => "ExVenture", "name" => "Player"}

      {:ok, _state} = Players.process_sign_in(state, %{"payload" => payload})

      assert [{"ExVenture", "Player"}] = PlayerCallbacks.sign_ins()
    end

    test "handle receive", %{state: state} do
      payload = %{"game" => "ExVenture", "name" => "Player"}

      {:ok, _state} = Players.handle_receive(state, %{"event" => "players/sign-in", "payload" => payload})
    end
  end

  describe "process an incoming players/sign-out event" do
    test "sends to the players callback", %{state: state} do
      payload = %{"game" => "ExVenture", "name" => "Player"}

      {:ok, _state} = Players.process_sign_out(state, %{"payload" => payload})

      assert [{"ExVenture", "Player"}] = PlayerCallbacks.sign_outs()
    end

    test "handle receive", %{state: state} do
      payload = %{"game" => "ExVenture", "name" => "Player"}

      {:ok, _state} = Players.handle_receive(state, %{"event" => "players/sign-out", "payload" => payload})
    end
  end

  describe "process an incoming players/status event" do
    test "sends to the players callback", %{state: state} do
      payload = %{"game" => "ExVenture", "players" => ["Player"]}

      {:ok, _state} = Players.process_status(state, %{"payload" => payload})

      assert [{"ExVenture", ["Player"]}] = PlayerCallbacks.player_updates()
    end

    test "missing a payload - when requesting a single game and that failed", %{state: state} do
      {:ok, _state} = Players.process_status(state, %{})
    end

    test "handle receive", %{state: state} do
      payload = %{"game" => "ExVenture", "players" => ["Player"]}

      {:ok, _state} = Players.handle_receive(state, %{"event" => "players/status", "payload" => payload})
    end
  end

  def with_state(_) do
    %{state: %{modules: %{players: Test.Callbacks.PlayerCallbacks}}}
  end
end
