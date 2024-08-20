defmodule OpenFeatureProviderFlagd.MixProject do
  use Mix.Project

  def project do
    [
      app: :open_feature_provider_flagd,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.27", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:open_feature, "~> 0.1"},
      {:req, "~> 0.5"},
      {:grpc, "~> 0.9.0"},
      {:google_protos, "~> 0.4.0"},
      {:protobuf_generate, "~> 0.1.1", only: [:dev], runtime: false}
    ]
  end
end
