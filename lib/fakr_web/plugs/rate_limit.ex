defmodule FakrWeb.Plugs.RateLimit do
  @moduledoc """
  Simple in-memory rate limiter using ETS.
  Generous defaults: 100 requests per minute per IP.
  """
  import Plug.Conn

  @table :rate_limit_table
  @limit 100
  @window_ms 60_000

  def init(opts), do: opts

  def call(conn, _opts) do
    ensure_table()
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    now = System.monotonic_time(:millisecond)

    case check_rate(ip, now) do
      :ok ->
        conn

      :rate_limited ->
        conn
        |> put_status(429)
        |> put_resp_header("retry-after", "60")
        |> Phoenix.Controller.json(%{
          "error" => "Rate limit exceeded. Max #{@limit} requests per minute.",
          "retry_after" => 60
        })
        |> halt()
    end
  end

  defp ensure_table do
    if :ets.info(@table) == :undefined do
      :ets.new(@table, [:set, :public, :named_table])
    end
  end

  defp check_rate(ip, now) do
    cutoff = now - @window_ms

    case :ets.lookup(@table, ip) do
      [{^ip, timestamps}] ->
        recent = Enum.filter(timestamps, &(&1 > cutoff))

        if length(recent) >= @limit do
          :rate_limited
        else
          :ets.insert(@table, {ip, [now | recent]})
          :ok
        end

      [] ->
        :ets.insert(@table, {ip, [now]})
        :ok
    end
  end
end
