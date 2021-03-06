defmodule HttpcBench.MixProject do
  use Mix.Project

  def project do
    [
      app: :httpc_bench,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:buoy, git: "https://github.com/lpgauth/buoy.git"},
      {:dlhttpc, git: "https://github.com/ferd/dlhttpc.git"},
      {:hackney, "~> 1.15.1"},
      {:ibrowse, "~> 4.4.1"},
      {:machine_gun, "~> 0.1.5"},
      {:mojito, git: "https://github.com/appcues/mojito.git", branch: "autopool"},
      {:timing, git: "https://github.com/lpgauth/timing.git"},
      {:metal, "0.1.1", override: true},
      {:cowboy, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:freedom_formatter, "~> 1.0"},
    ]
  end
end
