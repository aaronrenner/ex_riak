defmodule ExRiak.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_riak,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      deps: deps(),

      # Docs
      name: "ExRiak",
      source_url: "https://github.com/aaronrenner/ex_riak",
      docs: docs(),
      dialyzer: [plt_add_apps: [:ex_unit]],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:riakc, "~> 2.5.1"},

      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
    ]
  end

  # Run "mix help docs" to learn about docs
  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
    ]
  end
end
