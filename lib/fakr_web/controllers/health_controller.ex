defmodule FakrWeb.HealthController do
  use FakrWeb, :controller

  def index(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok", timestamp: DateTime.utc_now() |> DateTime.to_iso8601()}))
  end
end
