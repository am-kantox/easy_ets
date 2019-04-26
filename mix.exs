defmodule NimbleETS.MixProject do
  use Mix.Project

  @app :nimble_ets
  # @app_name Atom.to_string(@app)
  @version "0.1.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      package: package(),
      xref: [exclude: []],
      description: description(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :envio],
      mod: {NimbleETS.Application, []}
    ]
  end

  defp deps do
    [
      {:envio, "~> 0.4"},
      {:credo, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.20", only: :dev, override: true}
    ]
  end

  defp description do
    """
    The very simple ETS wrapper simplifying cross-process ETS handling (like `Agent`, but `:ets`).
    """
  end

  defp package do
    [
      name: @app,
      files: ~w|config lib mix.exs README.md|,
      maintainers: ["Aleksei Matiushkin"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/am-kantox/#{@app}",
        "Docs" => "https://hexdocs.pm/#{@app}"
      }
    ]
  end

  defp docs() do
    [
      # main: @app_name,
      main: "NimbleETS",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/#{@app}",
      # logo: "stuff/logo-48x48.png",
      source_url: "https://github.com/am-kantox/#{@app}",
      extras: [
        # "stuff/#{@app}.md"
      ],
      groups_for_modules: [
        # NimbleETS
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
