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
end
