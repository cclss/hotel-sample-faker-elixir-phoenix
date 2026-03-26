defmodule FakrWeb.ApiController do
  use FakrWeb, :controller

  alias Fakr.Accounts
  alias Fakr.Mocks
  alias Fakr.ApiLogger

  # Params that should NOT be used as data filters
  @reserved_params ~w(username collection_slug resource_slug id path delay status _client)

  def options(conn, _params) do
    send_resp(conn, 204, "")
  end

  def index(conn, params) do
    start = System.monotonic_time(:microsecond)

    result =
      with :ok <- maybe_delay(params),
           :ok <- maybe_error(conn, params),
           {:ok, resource, collection_key} <- resolve_resource_with_key(params),
           true <- resource.published || {:error, :not_published} do
        query_params = Map.drop(params, @reserved_params)

        {records, pagination} = Mocks.get_generated_records(resource.id, query_params)
        plural_name = resource.name |> Inflex.pluralize() |> String.downcase()

        conn = json(conn, %{
          "data" => %{
            plural_name => Enum.map(records, & &1.data),
            "pagination" => pagination
          }
        })

        log_api_request(conn, params, collection_key, start)
        conn
      else
        {:error_response, conn, collection_key} ->
          log_api_request(conn, params, collection_key, start)
          conn

        {:error_response, conn} ->
          conn

        {:error, _} ->
          conn |> put_status(404) |> json(%{"error" => "Not found"})
      end

    result
  end

  def show(conn, params) do
    start = System.monotonic_time(:microsecond)

    result =
      with :ok <- maybe_delay(params),
           :ok <- maybe_error(conn, params),
           {:ok, resource, collection_key} <- resolve_resource_with_key(params),
           true <- resource.published || {:error, :not_published},
           {id, _} <- Integer.parse(params["id"]),
           record when not is_nil(record) <- Mocks.get_generated_record(resource.id, id) do
        singular_name = resource.name |> Inflex.singularize() |> String.downcase()

        conn = json(conn, %{
          "data" => %{
            singular_name => record.data
          }
        })

        log_api_request(conn, params, collection_key, start)
        conn
      else
        {:error_response, conn, collection_key} ->
          log_api_request(conn, params, collection_key, start)
          conn

        {:error_response, conn} ->
          conn

        nil ->
          conn |> put_status(404) |> json(%{"error" => "Record not found"})

        :error ->
          conn |> put_status(404) |> json(%{"error" => "Invalid ID"})

        {:error, _} ->
          conn |> put_status(404) |> json(%{"error" => "Not found"})
      end

    result
  end

  # ── Logging ──

  defp log_api_request(conn, params, collection_key, start) do
    duration = System.monotonic_time(:microsecond) - start
    entry = ApiLogger.build_entry(conn, params, duration)
    ApiLogger.log_request(collection_key, entry)
  end

  # ── Delay / Error simulation ──

  defp maybe_delay(%{"delay" => ms_str}) do
    case Integer.parse(ms_str) do
      {ms, _} when ms > 0 -> Process.sleep(min(ms, 10_000))
      _ -> :ok
    end

    :ok
  end

  defp maybe_delay(_), do: :ok

  defp maybe_error(conn, %{"status" => status_str} = params) do
    case Integer.parse(status_str) do
      {status, _} when status >= 400 and status < 600 ->
        conn =
          conn
          |> put_status(status)
          |> json(%{"error" => "Simulated #{status} error", "simulated" => true})

        # Try to get collection_key for logging
        case resolve_collection_key(params) do
          {:ok, key} -> {:error_response, conn, key}
          _ -> {:error_response, conn}
        end

      _ ->
        :ok
    end
  end

  defp maybe_error(_, _), do: :ok

  # ── Resource resolution ──

  defp resolve_resource_with_key(%{
         "username" => username,
         "collection_slug" => collection_slug,
         "resource_slug" => resource_slug
       }) do
    user = Accounts.get_user_by_username!(username)
    collection = Mocks.get_collection_by_slug!(user.id, collection_slug)
    resource = Mocks.get_resource_by_slug!(collection.id, resource_slug)
    {:ok, resource, "#{username}/#{collection_slug}"}
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  defp resolve_collection_key(%{"username" => u, "collection_slug" => c}), do: {:ok, "#{u}/#{c}"}
  defp resolve_collection_key(_), do: :error
end
