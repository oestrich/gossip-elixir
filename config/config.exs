use Mix.Config

config :gossip, :url, "wss://gossip.haus/socket"
config :gossip, :client_id,  nil
config :gossip, :client_secret, nil
config :gossip, :callback_module, Gossip.TestCallback
