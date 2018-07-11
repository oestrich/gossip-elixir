defmodule GossipTest do
  use ExUnit.Case
  doctest Gossip

  test "greets the world" do
    assert Gossip.hello() == :world
  end
end
