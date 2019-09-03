use Mix.Config

config :gossip, :url, "wss://grapevine.haus/socket"
config :gossip, :client_id,  nil
config :gossip, :client_secret, nil
config :gossip, :callback_modules,
  core: Gossip.TestCallback.Core,
  players: Gossip.TestCallback.Players,
  tells: Gossip.TestCallback.Tells,
  games: Gossip.TestCallback.Games,
  system: nil

if Mix.env == :test do
  config :logger, :level, :warn

  config :gossip, :callback_modules,
    core: Test.Callbacks.CoreCallbacks,
    players: Test.Callbacks.PlayerCallbacks,
    tells: Test.Callbacks.TellCallbacks,
    games: Test.Callbacks.GameCallbacks
end

if File.exists?("config/local.exs") do
  import_config("local.exs")
end
