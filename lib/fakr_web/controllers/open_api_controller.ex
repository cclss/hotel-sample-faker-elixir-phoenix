defmodule FakrWeb.OpenApiController do
  use FakrWeb, :controller

  alias Fakr.Accounts
  alias Fakr.Mocks

  def show(conn, %{"username" => username, "collection_slug" => slug}) do
    user = Accounts.get_user_by_username!(username)
    collection = Mocks.get_collection_by_slug!(user.id, slug)
    base_url = FakrWeb.Endpoint.url()
    api_prefix = "/@#{username}/#{slug}/api"

    published_resources =
      collection.resources
      |> Enum.filter(& &1.published)
      |> Enum.reject(&String.starts_with?(&1.name, "_"))

    paths =
      Enum.reduce(published_resources, %{}, fn resource, acc ->
        list_path = "#{api_prefix}/#{resource.slug}"
        detail_path = "#{api_prefix}/#{resource.slug}/{id}"
        plural = Inflex.pluralize(resource.name) |> String.downcase()
        singular = Inflex.singularize(resource.name) |> String.downcase()

        schema_ref = "#/components/schemas/#{camelize(resource.name)}"

        acc
        |> Map.put(list_path, %{
          "get" => %{
            "summary" => "List #{plural}",
            "operationId" => "list_#{plural}",
            "tags" => [resource.name],
            "parameters" => list_parameters(),
            "responses" => %{
              "200" => %{
                "description" => "Successful response",
                "content" => %{
                  "application/json" => %{
                    "schema" => %{
                      "type" => "object",
                      "properties" => %{
                        "data" => %{
                          "type" => "object",
                          "properties" => %{
                            plural => %{
                              "type" => "array",
                              "items" => %{"$ref" => schema_ref}
                            },
                            "pagination" => %{"$ref" => "#/components/schemas/Pagination"}
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        })
        |> Map.put(detail_path, %{
          "get" => %{
            "summary" => "Get #{singular} by ID",
            "operationId" => "get_#{singular}",
            "tags" => [resource.name],
            "parameters" => [
              %{"name" => "id", "in" => "path", "required" => true, "schema" => %{"type" => "integer"}}
            ],
            "responses" => %{
              "200" => %{
                "description" => "Successful response",
                "content" => %{
                  "application/json" => %{
                    "schema" => %{
                      "type" => "object",
                      "properties" => %{
                        "data" => %{
                          "type" => "object",
                          "properties" => %{
                            singular => %{"$ref" => schema_ref}
                          }
                        }
                      }
                    }
                  }
                }
              },
              "404" => %{"description" => "Not found"}
            }
          }
        })
      end)

    schemas =
      published_resources
      |> Enum.reject(&String.starts_with?(&1.name, "_"))
      |> Enum.reduce(%{}, fn resource, acc ->
        fields = Enum.reject(resource.fields, &String.starts_with?(&1.name, "__group_meta."))
        properties = build_properties(fields)

        Map.put(acc, camelize(resource.name), %{
          "type" => "object",
          "properties" => Map.put(properties, "id", %{"type" => "integer"})
        })
      end)
      |> Map.put("Pagination", %{
        "type" => "object",
        "properties" => %{
          "page" => %{"type" => "integer"},
          "limit" => %{"type" => "integer"},
          "total" => %{"type" => "integer"},
          "current_page" => %{"type" => "integer"},
          "has_next" => %{"type" => "boolean"},
          "has_prev" => %{"type" => "boolean"},
          "last_page_no" => %{"type" => "integer"}
        }
      })

    spec = %{
      "openapi" => "3.0.3",
      "info" => %{
        "title" => collection.name,
        "description" => collection.description || "Mock API powered by Fakr",
        "version" => "1.0.0"
      },
      "servers" => [%{"url" => base_url}],
      "paths" => paths,
      "components" => %{"schemas" => schemas}
    }

    json(conn, spec)
  rescue
    Ecto.NoResultsError ->
      conn |> put_status(404) |> json(%{"error" => "Not found"})
  end

  defp list_parameters do
    [
      %{"name" => "page", "in" => "query", "schema" => %{"type" => "integer", "default" => 1}},
      %{"name" => "limit", "in" => "query", "schema" => %{"type" => "integer", "default" => 10}},
      %{"name" => "sort", "in" => "query", "schema" => %{"type" => "string"}, "description" => "Sort by field"},
      %{"name" => "order", "in" => "query", "schema" => %{"type" => "string", "enum" => ["asc", "desc"]}},
      %{"name" => "search_column", "in" => "query", "schema" => %{"type" => "string"}, "description" => "Field to search"},
      %{"name" => "search_term", "in" => "query", "schema" => %{"type" => "string"}, "description" => "Search keyword"},
      %{"name" => "delay", "in" => "query", "schema" => %{"type" => "integer"}, "description" => "Response delay (ms)"},
      %{"name" => "status", "in" => "query", "schema" => %{"type" => "integer"}, "description" => "Simulate error status"}
    ]
  end

  defp build_properties(fields) do
    Enum.reduce(fields, %{}, fn field, acc ->
      {key, schema} = field_to_schema(field)
      Map.put(acc, key, schema)
    end)
  end

  defp field_to_schema(field) do
    bare_name =
      case String.split(field.name, ".", parts: 2) do
        [_, bare] -> bare
        [bare] -> bare
      end

    type = infer_type(field.faker_category, field.faker_function)
    opts = field.options || %{}
    is_array = opts["is_array"] == "true"

    schema =
      if is_array do
        %{"type" => "array", "items" => type}
      else
        type
      end

    {bare_name, schema}
  end

  defp infer_type("Custom", "integer"), do: %{"type" => "integer"}
  defp infer_type("Custom", "float"), do: %{"type" => "number"}
  defp infer_type("Custom", "price"), do: %{"type" => "string", "example" => "$42.99"}
  defp infer_type("Custom", "boolean"), do: %{"type" => "boolean"}
  defp infer_type("Custom", "date_range"), do: %{"type" => "string", "format" => "date"}
  defp infer_type("UUID", _), do: %{"type" => "string", "format" => "uuid"}
  defp infer_type("Custom", "nanoid"), do: %{"type" => "string"}
  defp infer_type("Custom", "ulid"), do: %{"type" => "string"}
  defp infer_type("Date", _), do: %{"type" => "string", "format" => "date"}
  defp infer_type("DateTime", _), do: %{"type" => "string", "format" => "date-time"}
  defp infer_type("Internet", "email"), do: %{"type" => "string", "format" => "email"}
  defp infer_type("Internet", "url"), do: %{"type" => "string", "format" => "uri"}
  defp infer_type("Internet", "ip_v4_address"), do: %{"type" => "string", "format" => "ipv4"}
  defp infer_type("Commerce", "price"), do: %{"type" => "number"}
  defp infer_type("Address", "latitude"), do: %{"type" => "number"}
  defp infer_type("Address", "longitude"), do: %{"type" => "number"}
  defp infer_type(_, _), do: %{"type" => "string"}

  defp camelize(name) do
    name
    |> String.split(~r/[\s_-]+/)
    |> Enum.map(&String.capitalize/1)
    |> Enum.join()
  end
end
