# Gossip

A client for connecting to the Gossip MUD chat network. See [https://gossip.haus/docs](https://gossip.haus/docs) for more information.

## Installation

The package can be installed by adding `gossip` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gossip, "~> 0.1.0"},
  ]
end
```

## Configuration

Set the following in your mix project's configuration. **Do not commit the client id and secret.** These should be in a `prod.secret.exs` file or similar that is ignored from your repo.

```elixir
config :gossip, :callback_module, Game.GossipCallback
config :gossip, :client_id, "CLIENT ID"
config :gossip, :client_secret, "CLIENT SECRET"
```

The `Game.GossipCallback` module should use the behaviour `Gossip.Client`.
