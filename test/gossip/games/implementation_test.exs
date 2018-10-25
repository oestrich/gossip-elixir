defmodule Gossip.Games.ImplementationTest do
  use ExUnit.Case

  alias Gossip.Games.Implementation

  describe "listing games" do
    test "view cached games" do
      state = %{games: %{"ExVenture" => %{"game" => "ExVenture"}}}

      {:ok, games} = Implementation.list(state)
      assert games == [%{"game" => "ExVenture"}]
    end
  end

  describe "updating a game" do
    test "updates the state" do
      state = %{games: %{}}
      game = %{"game" => "ExVenture"}
      {:ok, state} = Implementation.update_game(state, game)

      assert state.games["ExVenture"]
    end
  end
end
