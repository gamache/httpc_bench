defmodule HttpcBench.Server do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(
        :http,
        HttpcBench.Server.PlugRouter,
        [],
        port: HttpcBench.Config.port()
      ),
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

defmodule HttpcBench.Server.PlugRouter do
  use Plug.Router

  plug(:match)

  plug(:dispatch)

  get "/" do
    name = conn.params["name"] || "world"
    send_resp(conn, 200, "Hello #{name}!")
  end

  get "/wait" do
    delay = (conn.params["d"] || "100") |> String.to_integer()
    :timer.sleep(delay)
    send_resp(conn, 200, "ok")
  end
end