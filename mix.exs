defmodule ExRiak.Mixfile do
  use Mix.Project

  @version "0.3.0"
  @maintainers ["Aaron Renner"]
  @source_url "https://github.com/aaronrenner/ex_riak"

  def project do
    [
      app: :ex_riak,
      version: @version,
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      # Docs
      name: "ExRiak",
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
      {:inch_ex, ">= 0.5.0", only: :docs},
    ]
  end

  # Run "mix help docs" to learn about docs
  defp docs do
    [
      main: "ExRiak",
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end

  defp description do
    "Simple wrapper for riakc (riak-erlang-client)"
  end

  defp package do
    [
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{
        "Github" => @source_url
      }
    ]
  end
end
