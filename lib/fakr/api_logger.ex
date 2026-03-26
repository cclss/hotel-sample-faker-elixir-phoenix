defmodule Fakr.ApiLogger do
  @moduledoc """
  In-memory API request logger using ETS ring buffer.
  Keeps last N requests per collection. Broadcasts via PubSub for live updates.
  """

  @table :api_request_log
  @max_entries 50

  def init do
    if :ets.info(@table) == :undefined do
      :ets.new(@table, [:set, :public, :named_table])
    end
  end

  @doc """
  Log an API request. Called from ApiController after response.
  """
  def log_request(collection_key, entry) do
    init()

    entries =
      case :ets.lookup(@table, collection_key) do
        [{_, list}] -> list
        [] -> []
      end

    # Ring buffer: keep last @max_entries
    updated = Enum.take([entry | entries], @max_entries)
    :ets.insert(@table, {collection_key, updated})

    # Broadcast to LiveView subscribers
    Phoenix.PubSub.broadcast(
      Fakr.PubSub,
      "api_log:#{collection_key}",
      {:new_request, entry}
    )
  end

  @doc """
  Get recent requests for a collection, optionally filtered by client ID.
  """
  def get_requests(collection_key, client_id \\ nil) do
    init()

    entries =
      case :ets.lookup(@table, collection_key) do
        [{_, list}] -> list
        [] -> []
      end

    case client_id do
      nil -> entries
      "" -> entries
      id -> Enum.filter(entries, &(&1.client == id))
    end
  end

  @doc """
  Build a log entry from conn after response.
  """
  def build_entry(conn, params, duration_us) do
    resp_body =
      case conn.resp_body do
        body when is_binary(body) ->
          # Pretty-print JSON, truncate if too large
          case Jason.decode(body) do
            {:ok, decoded} -> Jason.encode!(decoded, pretty: true) |> String.slice(0, 4096)
            _ -> String.slice(body, 0, 4096)
          end

        _ ->
          nil
      end

    %{
      id: System.unique_integer([:positive]),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      method: conn.method,
      path: conn.request_path,
      query_string: conn.query_string,
      status: conn.status,
      duration_ms: Float.round(duration_us / 1000, 1),
      resource: params["resource_slug"],
      client: params["_client"] || nil,
      request_headers: filter_headers(conn.req_headers),
      response_headers: filter_headers(conn.resp_headers),
      response_body: resp_body
    }
  end

  defp filter_headers(headers) do
    # Keep useful headers, drop noisy internal ones
    skip = ~w(x-request-id x-forwarded-for x-forwarded-proto x-forwarded-port)

    headers
    |> Enum.reject(fn {k, _} -> k in skip end)
    |> Enum.take(20)
  end
end
