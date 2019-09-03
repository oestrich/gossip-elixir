defmodule Gossip.MixProject do
  use Mix.Project

  def project do
    [
      app: :gossip,
      version: "1.2.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env),
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

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_uuid, "~> 1.2"},
      {:credo, "~> 0.10", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:poison, "~> 3.1"},
      {:telemetry, "~> 0.4"},
      {:timex, "~> 3.1"},
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
