defmodule Warpath.MixProject do
  use Mix.Project
  @description "A implementation of Jsonpath expression for Elixir."
  @version "0.6.2"

  def project do
    [
      app: :warpath,
      name: "Warpath",
      description: @description,
      version: @version,
      elixir: "~> 1.7",
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/cleidiano/warpath",
      docs: [main: "Warpath"],
      dialyzer: [
        plt_core_path: "_build/#{Mix.env()}"
      ]
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
      {:jason, "~> 1.2"},
      {:yaml_elixir, "~> 2.4", only: :test},
      {:stream_data, "~> 0.1", only: [:test, :dev]},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "1.6.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    %{
      maintainers: ["Cleidiano Oliveira"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/cleidiano/warpath"
      }
    }
  end
end
