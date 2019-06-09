defmodule Stopsel.MixProject do
  use Mix.Project

  def project do
    [
      app: :stopsel,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: [
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ~w"lib test/support"
  defp elixirc_paths(_), do: ~w"lib"
end
