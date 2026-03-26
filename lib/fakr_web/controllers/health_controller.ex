defmodule FakrWeb.HealthController do
  use FakrWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", timestamp: DateTime.utc_now() |> DateTime.to_iso8601()})
  end
end
