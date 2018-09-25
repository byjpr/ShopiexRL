defmodule ShopiexRL.Mixfile do
  use Mix.Project

  @description """
    Making sure to not blow over Shopify apps Rate Limits
  """

  def project do
    [
      app: :shopiexrl,
      version: "0.1.0",
      elixir: "~> 1.5",
      name: "ShopiexRL",
      description: @description,
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :event_bus, :memento],
      mod: {ShopiexRL, []}
    ]
  end

  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:machinery, "~> 0.16.0"},
      # Data
      {:memento, "~> 0.2.1"},
      # Events
      {:event_bus, "~> 1.5.0"},
      {:event_bus_logger, "~> 0.1.6"},
      # Intergrations
      {:tesla, "~> 1.1.0", optional: true},
      # Testing
      {:earmark, "~> 1.2.6", only: :dev},
      {:ex_doc, "~> 0.19.1", only: :dev},
      {:inch_ex, "~> 1.0.0", only: :dev},
      {:excoveralls, "~> 0.5", only: :test},
      {:exvcr, "~> 0.10.2", only: :test},
      {:meck, "~> 0.8.9", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Jordan Parker"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/byjord/shopiexrl"}
    ]
  end
end
