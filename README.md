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
