defmodule ExTrace.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_trace,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :kv_server]]
  end

  defp deps do
    [
      {:ex_kv, git: "https://github.com/mentels/ex_kv.git"},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end
end
