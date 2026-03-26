defmodule FakrWeb.Plugs.RateLimit do
  @moduledoc """
  Simple in-memory rate limiter using ETS.
  100 requests per minute per IP. Cleans up stale entries periodically.
  """
  import Plug.Conn

  @table :rate_limit_table
  @limit 100
  @window_ms 60_000
  @cleanup_interval_ms 120_000

  def init(opts), do: opts

  def call(conn, _opts) do
    ensure_table()
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    now = System.monotonic_time(:millisecond)

    maybe_cleanup(now)

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
          :ets.insert(@table, {ip, recent})
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

  defp maybe_cleanup(now) do
    last_cleanup =
      case :ets.lookup(@table, :__last_cleanup) do
        [{_, ts}] -> ts
        [] -> 0
      end

    if now - last_cleanup > @cleanup_interval_ms do
      :ets.insert(@table, {:__last_cleanup, now})
      cutoff = now - @window_ms

      :ets.foldl(
        fn
          {:__last_cleanup, _}, acc ->
            acc

          {ip, timestamps}, acc ->
            recent = Enum.filter(timestamps, &(&1 > cutoff))

            if recent == [] do
              :ets.delete(@table, ip)
            else
              :ets.insert(@table, {ip, recent})
            end

            acc
        end,
        nil,
        @table
      )
    end
  end
end
