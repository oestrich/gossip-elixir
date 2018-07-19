defmodule Gossip.TestCallback do
  @moduledoc false

  @behaviour Gossip.Client

  @impl true
  def user_agent(), do: "Test Client"

  @impl true
  def channels(), do: []

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
end
