defmodule Metasploit.MixProject do
  use Mix.Project

  def project do
    [
      app: :metasploit,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "metasploit",
      description: "Elixir API for the Metasploit RPC API",
      package: package()
    ]
  end

  def package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Grant Murphy"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/gcmurphy/metasploit_ex"}
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
      {:tesla, "~> 1.2"},
      {:jason, "~> 1.1"},
      {:msgpax, "~> 2.2"}
    ]
  end
end
