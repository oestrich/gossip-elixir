defmodule Gossip do
  use Application

  alias Gossip.Client
  alias Gossip.Tells

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Gossip.Supervisor, []),
      {Tells, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @moduledoc """
  Gossip client

  https://github.com/oestrich/gossip
  """

  @type channel :: String.t()

  @doc false
  def client_id(), do: Application.get_env(:gossip, :client_id)

  @doc false
  def configured?(), do: client_id() != nil

  @doc false
  def start_socket(), do: Gossip.Supervisor.start_socket()

  @doc """
  Send a message to the Gossip network
  """
  @spec broadcast(Client.channel_name(), Message.send()) :: :ok
  def broadcast(channel, message) do
    maybe_send({:broadcast, channel, message})
  end

  @doc """
  Send a player sign in event
  """
  @spec player_sign_in(Client.player_name()) :: :ok
  def player_sign_in(player_name) do
    maybe_send({:player_sign_in, player_name})
  end

  @doc """
  Send a player sign out event
  """
  @spec player_sign_out(Client.player_name()) :: :ok
  def player_sign_out(player_name) do
    maybe_send({:player_sign_out, player_name})
  end

  @doc """
  Check Gossip for players that are online.

  The callback you will receive is `Gossip.Client.players_status/2`.
  """
  @spec request_players_online() :: :ok
  def request_players_online() do
    maybe_send(:players_status)
  end

  @doc """
  Send a tell to a remote game and player.
  """
  @spec send_tell(Client.player_name(), Client.game_name(), Client.player_name(), Client.message()) ::
    :ok | {:error, :offline} | {:error, String.t()}
  def send_tell(sending_player, game_name, player_name, message) do
    try do
      response = GenServer.call(Tells, {:tell, sending_player, game_name, player_name, message})

      case response do
        {:error, :offline} ->
          {:error, :offline}

        %{"status" => "success"} ->
          :ok

        %{"status" => "failure", "error" => error} ->
          {:error, error}
      end
    catch
      :exit, _ ->
        {:error, :offline}
    end
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
