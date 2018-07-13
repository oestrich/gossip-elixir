defmodule Gossip.MixProject do
  use Mix.Project

  def project do
    [
      app: :gossip,
      version: "0.2.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "readme",
        extras: ["README.md"]
      ],
      description: description(),
      package: package(),
      homepage_url: "https://gossip.haus/",
      source_url: "https://github.com/oestrich/gossip-elixir"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Gossip, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:poison, "~> 3.1"},
      {:websockex, "~> 0.4.0"}
    ]
  end

  def description() do
    "Client for the Gossip MUD network"
  end

  def package() do
    [
      maintainers: ["Eric Oestrich"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/oestrich/gossip-elixir"}
    ]
  end
end
