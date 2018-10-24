use Mix.Config

config :gossip, :url, "wss://gossip.haus/socket"
config :gossip, :client_id,  nil
config :gossip, :client_secret, nil
config :gossip, :callback_modules,
  core: Gossip.TestCallback.Core,
  players: Gossip.TestCallback.Core,
  tells: Gossip.TestCallback.Core,
  games: Gossip.TestCallback.Core,
  system: nil

if Mix.env == :test do
  config :logger, :level, :warn

  config :gossip, :callback_modules,
    core: Test.Callbacks.CoreCallbacks
end

if File.exists?("config/local.exs") do
  import_config("local.exs")
end
