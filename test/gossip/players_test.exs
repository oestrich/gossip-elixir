defmodule Gossip.PlayersTest do
  use ExUnit.Case, async: false

  alias Gossip.Players

  setup [:reset]

  describe "sign in" do
    test "adds the player to the current list" do
      Players.Internal.sign_in("ExVenture", "player")

      assert Players.who() == %{"ExVenture" => ["player"]}
    end

    test "double sign in message uniques the list" do
      Players.Internal.sign_in("ExVenture", "player")
      Players.Internal.sign_in("ExVenture", "player")

      assert Players.who() == %{"ExVenture" => ["player"]}
    end

    test "a second player - list is sorted" do
      Players.Internal.sign_in("ExVenture", "player1")
      Players.Internal.sign_in("ExVenture", "player2")

      assert Players.who() == %{"ExVenture" => ["player1", "player2"]}
    end
  end

  describe "sign out" do
    test "removes the player to the current list" do
      Players.Internal.sign_in("ExVenture", "player1")
      Players.Internal.sign_in("ExVenture", "player2")
      Players.Internal.sign_out("ExVenture", "player1")

      assert Players.who() == %{"ExVenture" => ["player2"]}
    end

    test "if last player on remote game signs out, clear the game from the list" do
      Players.Internal.sign_in("ExVenture", "player")
      Players.Internal.sign_out("ExVenture", "player")

      assert Players.who() == %{}
    end
  end

  describe "new full game list" do
    test "updates the local list" do
      Players.Internal.player_list("ExVenture", ["player"])

      assert Players.who() == %{"ExVenture" => ["player"]}
    end
  end

  describe "cleaning out games that haven't been seen recently" do
    test "keeps 'active' games" do
      state = %{
        games: %{
          "ExVenture" => %{
            last_seen: Timex.now() |> Timex.shift(minutes: -5),
            players: [],
          },
          "ExVenture 2" => %{
            last_seen: Timex.now(),
            players: [],
          },
        }
      }

      {:ok, state} = Players.Implementation.sweep_games(state)
      assert length(Map.keys(state.games)) == 1
    end
  end

  def reset(_) do
    Players.Internal.reset()
  end
end
