defmodule Gossip do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Gossip.Supervisor, [])
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @moduledoc """
  Gossip client

  https://github.com/oestrich/gossip
  """

  @type channel :: String.t()

  def client_id(), do: Application.get_env(:gossip, :client_id)

  def configured?(), do: client_id() != nil

  def start_socket(), do: Gossip.Supervisor.start_socket()

  @doc """
  Send a message to the Gossip network
  """
  @spec broadcast(Gossip.Client.channel_name(), Gossip.Message.send()) :: :ok
  def broadcast(channel, message) do
    maybe_send({:broadcast, channel, message})
  end

  @doc """
  Send a player sign in event
  """
  @spec player_sign_in(Gossip.Client.player_name()) :: :ok
  def player_sign_in(player_name) do
    maybe_send({:player_sign_in, player_name})
  end

  @doc """
  Send a player sign out event
  """
  @spec player_sign_out(Gossip.Client.player_name()) :: :ok
  def player_sign_out(player_name) do
    maybe_send({:player_sign_out, player_name})
  end

  @doc """
  Check Gossip for players that are online.

  You will get a callback per game that is online.
  """
  @spec request_players_online() :: :ok
  def request_players_online() do
    maybe_send(:players_status)
  end

  defp maybe_send(message) do
    case Process.whereis(Gossip.Socket) do
      nil ->
        :ok

      _pid ->
        WebSockex.cast(Gossip.Socket, message)
    end
  end
end
