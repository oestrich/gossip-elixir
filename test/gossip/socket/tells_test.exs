defmodule Gossip.Socket.TellsTest do
  use ExUnit.Case

  alias Gossip.Socket.Tells
  alias Test.Callbacks.TellCallbacks

  setup [:with_state]

  describe "process an incoming tells/send event" do
    test "sends to the players callback", %{state: state} do
      {:ok, _state} = Tells.process_send(state, %{})
    end

    test "handle receive", %{state: state} do
      {:ok, _state} = Tells.handle_receive(state, %{"event" => "tells/send"})
    end
  end

  describe "process an incoming tells/receive event" do
    test "sends to the tells callback", %{state: state} do
      payload = %{
        "from_game" => "ExVenture",
        "from_name" => "Player",
        "to_name" => "User",
        "sent_at" => "2018-07-17T13:2:28Z",
        "message" => "Hello"
      }

      {:ok, _state} = Tells.process_receive(state, %{"payload" => payload})

      assert [{"ExVenture", "Player", "User", "Hello"}] = TellCallbacks.receives()
    end

    test "handle receive", %{state: state} do
      payload = %{
        "from_game" => "ExVenture",
        "from_name" => "Player",
        "to_name" => "User",
        "sent_at" => "2018-07-17T13:2:28Z",
        "message" => "Hello"
      }

      {:ok, _state} = Tells.handle_receive(state, %{"event" => "tells/receive", "payload" => payload})
    end
  end

  def with_state(_) do
    %{state: %{modules: %{tells: Test.Callbacks.TellCallbacks}}}
  end
end
