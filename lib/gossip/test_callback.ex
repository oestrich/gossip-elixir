defmodule Gossip.TestCallback do
  @moduledoc false

  @behaviour Gossip.Client

  @impl true
  def user_agent(), do: "Test Client"

  @impl true
  def channels(), do: ["gossip"]

  @impl true
  def players(), do: []

  @impl true
  def message_broadcast(_message), do: :ok

  @impl true
  def player_sign_in(_game_name, _player_name), do: :ok

  @impl true
  def player_sign_out(_game_name, _player_name), do: :ok

  @impl true
  def players_status(_game_name, _player_names), do: :ok

  @impl true
  def tell_received(_from_game, _from_player, _to_player, _message), do: :ok

  @impl true
  def games_status(_game), do: :ok
end
