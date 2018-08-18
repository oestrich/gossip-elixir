defmodule Gossip.PlayersTest do
  use ExUnit.Case, async: false

  alias Gossip.Players

  setup [:reset]

  describe "sign in" do
    test "adds the player to the current list" do
      Players.sign_in("ExVenture", "player")

      assert Players.who() == %{"ExVenture" => ["player"]}
    end

    test "double sign in message uniques the list" do
      Players.sign_in("ExVenture", "player")
      Players.sign_in("ExVenture", "player")

      assert Players.who() == %{"ExVenture" => ["player"]}
    end

    test "a second player - list is sorted" do
      Players.sign_in("ExVenture", "player1")
      Players.sign_in("ExVenture", "player2")

      assert Players.who() == %{"ExVenture" => ["player1", "player2"]}
    end
  end

  describe "sign out" do
    test "removes the player to the current list" do
      Players.sign_in("ExVenture", "player1")
      Players.sign_in("ExVenture", "player2")
      Players.sign_out("ExVenture", "player1")

      assert Players.who() == %{"ExVenture" => ["player2"]}
    end

    test "if last player on remote game signs out, clear the game from the list" do
      Players.sign_in("ExVenture", "player")
      Players.sign_out("ExVenture", "player")

      assert Players.who() == %{}
    end
  end

  describe "new full game list" do
    test "updates the local list" do
      Players.player_list("ExVenture", ["player"])

      assert Players.who() == %{"ExVenture" => ["player"]}
    end
  end

  def reset(_) do
    Players.reset()
  end
end
