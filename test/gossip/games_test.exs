defmodule Gossip.GamesTest do
  use ExUnit.Case, async: false

  alias Gossip.Games

  setup [:reset]

  describe "updates local game cache" do
    test "new game" do
      Games.update_game(%{
        "game" => "ExVenture",
        "display_name" => "ExVenture MUD"
      })

      assert Games.list() == [
        %{"game" => "ExVenture", "display_name" => "ExVenture MUD"}
      ]
    end

    test "updates the local game" do
      Games.update_game(%{
        "game" => "ExVenture",
        "display_name" => "ExVenture MUD"
      })

      Games.update_game(%{
        "game" => "ExVenture",
        "display_name" => "ExVentures MUD"
      })

      assert Games.list() == [
        %{"game" => "ExVenture", "display_name" => "ExVentures MUD"}
      ]
    end
  end

  def reset(_) do
    Games.reset()
  end
end
