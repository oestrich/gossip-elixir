# Gossip

A client for connecting to the Gossip MUD chat network. See [https://gossip.haus/docs](https://gossip.haus/docs) for more information.

## Installation

The package can be installed by adding `gossip` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gossip, "~> 0.6"},
  ]
end
```

## Configuration

Set the following in your mix project's configuration. **Do not commit the client id and secret.** These should be in a `prod.secret.exs` file or similar that is ignored from your repo.

```elixir
config :gossip, :client_id, "CLIENT ID"
config :gossip, :client_secret, "CLIENT SECRET"
config :gossip, :callback_modules,
  core: Callbacks.Core,
  players: Callbacks.Players,
  tells: Callbacks.Tells,
  games: Callbacks.Games
```

## Callback Modules

You can opt into specific support flags on Gossip by configuring callback modules that follow the specific behaviours.

See a sample set of callbacks by viewing the `TestCallback` module for this client, [here](https://github.com/oestrich/gossip-elixir/blob/master/lib/gossip/test_callback.ex).

### Core/Channels

The `channels` flag *must* be supported and can be set up by providing a callback module that has the `Gossip.Client.Core` behaviour.

### Players

The `players` flag can be set up by providing a callback module that has the `Gossip.Client.Players` behaviour.

### Tells

The `tells` flag can be set up by providing a callback module that has the `Gossip.Client.Tells` behaviour.

### Games

the `games` flag can be set up by providing a callback module that has the `gossip.client.games` behaviour.

## Telemetry Events

- `[:gossip, :events, :channels, :broadcast]` - Received a `channels/broadcast` event
- `[:gossip, :events, :channels, :send]` - Sending a `channels/send` event
- `[:gossip, :events, :core, :authenticate]` - Received a response to `authenticate`
- `[:gossip, :events, :core, :authenticating]` - Sending an `authenticate` event
- `[:gossip, :events, :core, :heartbeat]` - Received a `heartbeat` event
- `[:gossip, :events, :core, :restart]` - Received a `restart` event
- `[:gossip, :events, :games, :connect]` - Received a `games/connect` event
- `[:gossip, :events, :games, :disconnect]` - Received a `games/disconnect` event
- `[:gossip, :events, :games, :status]` - Received a response to `games/status`
- `[:gossip, :events, :players, :sign_in]` - Received a `players/sign-in` event
- `[:gossip, :events, :players, :sign_out]` - Received a `players/sign-out` event
- `[:gossip, :events, :players, :status]` - Received a response to `players/sign-in`
