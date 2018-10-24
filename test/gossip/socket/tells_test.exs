defmodule Gossip.Socket.TellsTest do
  use ExUnit.Case

  alias Gossip.Socket.Tells
  alias Test.Callbacks.TellCallbacks

  describe "process an incoming tells/send event" do
    test "sends to the players callback" do
      {:ok, _state} = Tells.process_send(%{}, %{})
    end

    test "handle receive" do
      {:ok, _state} = Tells.handle_receive(%{}, %{"event" => "tells/send"})
    end
  end

  describe "process an incoming tells/receive event" do
    test "sends to the tells callback" do
      payload = %{
        "from_game" => "ExVenture",
        "from_name" => "Player",
        "to_name" => "User",
        "sent_at" => "2018-07-17T13:2:28Z",
        "message" => "Hello"
      }

      {:ok, _state} = Tells.process_receive(%{}, %{"payload" => payload})

      assert [{"ExVenture", "Player", "User", "Hello"}] = TellCallbacks.receives()
    end

    test "handle receive" do
      payload = %{
        "from_game" => "ExVenture",
        "from_name" => "Player",
        "to_name" => "User",
        "sent_at" => "2018-07-17T13:2:28Z",
        "message" => "Hello"
      }

      {:ok, _state} = Tells.handle_receive(%{}, %{"event" => "tells/receive", "payload" => payload})
    end
  end
end
