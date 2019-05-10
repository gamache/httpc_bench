defmodule HttpcBench do
  @moduledoc """
  Documentation for HttpcBench.
  """

  alias HttpcBench.Config

  def run_server do
    HttpcBench.Server.start([], [])
  end

  def run_clients(opts \\ []) do
    print_header(opts)
    print_results(opts)
    print_footer(opts)
  end

  defp print_results(opts) do
    for concurrency <- Config.concurrencies(),
        pool_size <- Config.pool_sizes(),
        pool_count <- Config.pool_counts(),
        client <- Config.clients() do
      result(client, concurrency, pool_size, pool_count)
      |> print_result(opts)

      Process.sleep(100)
    end
  end

  defp result(client, concurrency, pool_size, pool_count) do
    client_name = client |> to_string |> String.replace_leading("Elixir.HttpcBench.Client.", "")
    name = name(client_name, concurrency, pool_size, pool_count)

    case client.start(pool_size, pool_count) do
      {:error, err} ->
        %{
          client: client_name,
          name: name,
          concurrency: concurrency,
          pool_size: pool_size,
          pool_count: pool_count,
          results: [],
          qps: 0,
          errors: 0,
          message: err,
        }

      :ok ->
        fun = fn -> get_until_success(client) end

        results =
          :timing_hdr.run(
            fun,
            name: name,
            concurrency: concurrency,
            iterations: Config.iterations(),
            output: "output/#{name}" |> String.to_charlist()
          )

        qps = results[:success] / (results[:total_time] / 1_000_000)
        errors = results[:errors] * 100 / results[:iterations]

        client.stop()

        %{
          client: client_name,
          name: name,
          concurrency: concurrency,
          pool_size: pool_size,
          pool_count: pool_count,
          results: results,
          qps: qps,
          errors: errors,
        }
    end
  end

  defp get_until_success(client) do
    case client.get() do
      :ok -> :ok
      _ -> get_until_success(client)
    end
  end

  defp print_header(opts) do
    case output_format(opts) do
      :text ->
        :io.format(
          "Running benchmark...~n~n" <>
            "Client     PoolCount  PoolSize  Concurrency  Requests/s  Error %~n"
        )

      :html ->
        ~S"""
        <table>
        <thead><tr><th>Client</th><th>Pool Count</th><th>Pool Size</th><th>Concurrency</th><th>Req/sec</th><th>Error %</th></tr></thead>
        <tfoot><tr><th>Client</th><th>Pool Count</th><th>Pool Size</th><th>Concurrency</th><th>Req/sec</th><th>Error %</th></tr></tfoot>
        """
        |> String.trim
        |> IO.puts()

      :csv ->
        "Client,Pool Count,Pool Size,Concurrency,Req/sec,Error %"
        |> IO.puts()
    end
  end

  ## Don't print skipped runs
  defp print_result(%{message: _}, _opts), do: :ok

  defp print_result(result, opts) do
    fields = [
      result.client,
      result.pool_count,
      result.pool_size,
      result.concurrency,
      trunc(result.qps),
      round(result.errors * 10) / 10.0,
    ]

    case output_format(opts) do
      :text ->
        :io.format("~-10s ~9B ~9B ~12B ~11B ~8.1f~n", fields)

      :html ->
        "<tr><td>#{Enum.join(fields, "</td><td>")}</td></tr>" |> IO.puts()

      :csv ->
        fields |> Enum.join(",") |> IO.puts()
    end
  end

  defp print_footer(opts) do
    case output_format(opts) do
      :html -> "</table>" |> IO.puts()
      _ -> :nothing_to_do
    end
  end

  defp name(client, concurrency, pool_size, pool_count) do
    "#{client}_conc#{concurrency}_size#{pool_size}_count#{pool_count}"
    |> String.to_atom()
  end

  def output_format(opts) do
    opts[:output] || Application.get_env(:httpc_bench, :output, :text)
  end
end
