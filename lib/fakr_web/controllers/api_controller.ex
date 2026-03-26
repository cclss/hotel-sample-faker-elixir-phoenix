defmodule FakrWeb.ApiController do
  use FakrWeb, :controller

  alias Fakr.Accounts
  alias Fakr.Mocks

  @route_params ~w(username collection_slug resource_slug id path delay status)

  def options(conn, _params) do
    send_resp(conn, 204, "")
  end

  def index(conn, params) do
    with :ok <- maybe_delay(params),
         :ok <- maybe_error(conn, params),
         {:ok, resource} <- resolve_resource(params),
         true <- resource.published || {:error, :not_published} do
      query_params = Map.drop(params, @route_params)

      {records, pagination} = Mocks.get_generated_records(resource.id, query_params)
      plural_name = resource.name |> Inflex.pluralize() |> String.downcase()

      json(conn, %{
        "data" => %{
          plural_name => Enum.map(records, & &1.data),
          "pagination" => pagination
        }
      })
    else
      {:error_response, conn} -> conn
      {:error, _} -> conn |> put_status(404) |> json(%{"error" => "Not found"})
    end
  end

  def show(conn, params) do
    with :ok <- maybe_delay(params),
         :ok <- maybe_error(conn, params),
         {:ok, resource} <- resolve_resource(params),
         true <- resource.published || {:error, :not_published},
         {id, _} <- Integer.parse(params["id"]),
         record when not is_nil(record) <- Mocks.get_generated_record(resource.id, id) do
      singular_name = resource.name |> Inflex.singularize() |> String.downcase()

      json(conn, %{
        "data" => %{
          singular_name => record.data
        }
      })
    else
      {:error_response, conn} -> conn
      nil -> conn |> put_status(404) |> json(%{"error" => "Record not found"})
      :error -> conn |> put_status(404) |> json(%{"error" => "Invalid ID"})
      {:error, _} -> conn |> put_status(404) |> json(%{"error" => "Not found"})
    end
  end

  # ?delay=2000 → sleep 2 seconds (max 10s)
  defp maybe_delay(%{"delay" => ms_str}) do
    case Integer.parse(ms_str) do
      {ms, _} when ms > 0 -> Process.sleep(min(ms, 10_000))
      _ -> :ok
    end

    :ok
  end

  defp maybe_delay(_), do: :ok

  # ?status=500 → return that status code
  defp maybe_error(conn, %{"status" => status_str}) do
    case Integer.parse(status_str) do
      {status, _} when status >= 400 and status < 600 ->
        conn =
          conn
          |> put_status(status)
          |> json(%{"error" => "Simulated #{status} error", "simulated" => true})

        {:error_response, conn}

      _ ->
        :ok
    end
  end

  defp maybe_error(_, _), do: :ok

  defp resolve_resource(%{
         "username" => username,
         "collection_slug" => collection_slug,
         "resource_slug" => resource_slug
       }) do
    user = Accounts.get_user_by_username!(username)
    collection = Mocks.get_collection_by_slug!(user.id, collection_slug)
    resource = Mocks.get_resource_by_slug!(collection.id, resource_slug)
    {:ok, resource}
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end
end
