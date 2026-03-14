defmodule ProGen.MixProject do
  use Mix.Project

  @version "0.0.1"
  @source_url "https://github.com/andyl/pro_gen"

  def project do
    [
      app: :pro_gen,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      usage_rules: usage_rules(),
      deps: deps(),
      # Documentation
      name: "ProGen",
      source_url: @source_url,
      homepage_url: @source_url,
      source_ref: "v#{@version}",
      docs: [
        main: "overview",
        logo: "assets/logo.svg",
        favicon: "assets/favicon.svg",
        source_ref: "master",
        extras: [
          {"README.md", title: "Overview", filename: "overview"},
          "LICENSE.txt"
        ],
        assets: %{"assets" => "assets"}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp usage_rules do
    [
      file: "RULES.md",
      usage_rules: [{~r/.*/, link: :markdown}],
      skills: [
        location: ".claude/skills",
        build: []
      ]
    ]
  end

  defp deps do
    [
      {:igniter, "~> 0.6"},
      {:usage_rules, "~> 1.0"},
      {:nimble_options, "~> 1.0"},
      {:optimus, "~> 0.5"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end
