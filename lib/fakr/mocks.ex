defmodule Fakr.Mocks do
  import Ecto.Query
  alias Fakr.Repo
  alias Fakr.Mocks.{Collection, Resource, ResourceField, GeneratedRecord}

  # --- Collections ---

  def list_user_collections(user_id) do
    from(c in Collection,
      where: c.user_id == ^user_id,
      order_by: [desc: c.updated_at],
      preload: [:resources]
    )
    |> Repo.all()
  end

  def get_user_collection!(user_id, id) do
    from(c in Collection,
      where: c.user_id == ^user_id and c.id == ^id,
      preload: [resources: :fields]
    )
    |> Repo.one!()
  end

  def get_collection_by_slug!(user_id, slug) do
    from(c in Collection,
      where: c.user_id == ^user_id and c.slug == ^slug,
      preload: [resources: :fields]
    )
    |> Repo.one!()
  end

  def create_collection(user, attrs) do
    result =
      %Collection{user_id: user.id}
      |> Collection.changeset(attrs)
      |> Repo.insert()

    # Auto-create a _health resource
    case result do
      {:ok, collection} ->
        create_health_resource(collection)
        {:ok, collection}

      error ->
        error
    end
  end

  defp create_health_resource(collection) do
    {:ok, resource} =
      %Resource{collection_id: collection.id}
      |> Resource.changeset(%{name: "_health", total_records: 1})
      |> Repo.insert()

    %ResourceField{resource_id: resource.id, position: 0}
    |> ResourceField.changeset(%{
      name: "status",
      faker_category: "Custom",
      faker_function: "pick",
      options: %{"items" => "ok"}
    })
    |> Repo.insert!()

    %ResourceField{resource_id: resource.id, position: 1}
    |> ResourceField.changeset(%{
      name: "timestamp",
      faker_category: "Custom",
      faker_function: "template",
      options: %{"template" => "{{DateTime.forward}}"}
    })
    |> Repo.insert!()

    generate_records(resource)
  end

  # --- Explore ---

  def list_explorable_collections(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    from(c in Collection,
      where: c.explorable == true,
      join: u in assoc(c, :user),
      preload: [:user, :resources],
      order_by: [desc: c.updated_at],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
  end

  def count_explorable_collections do
    Repo.one(from(c in Collection, where: c.explorable == true, select: count()))
  end

  def update_collection(%Collection{} = collection, attrs) do
    collection
    |> Collection.changeset(attrs)
    |> Repo.update()
  end

  def delete_collection(%Collection{} = collection) do
    Repo.delete(collection)
  end

  def change_collection(%Collection{} = collection, attrs \\ %{}) do
    Collection.changeset(collection, attrs)
  end

  # --- Resources ---

  def list_resources(collection_id) do
    from(r in Resource,
      where: r.collection_id == ^collection_id,
      order_by: [asc: r.name],
      preload: :fields
    )
    |> Repo.all()
  end

  def get_resource!(id) do
    Resource
    |> Repo.get!(id)
    |> Repo.preload(fields: from(f in ResourceField, order_by: [asc: f.position]))
  end

  def get_resource_by_slug!(collection_id, slug) do
    from(r in Resource,
      where: r.collection_id == ^collection_id and r.slug == ^slug,
      preload: :fields
    )
    |> Repo.one!()
  end

  def create_resource(collection, attrs) do
    %Resource{collection_id: collection.id}
    |> Resource.changeset(attrs)
    |> Repo.insert()
  end

  def update_resource(%Resource{} = resource, attrs) do
    resource
    |> Resource.changeset(attrs)
    |> Repo.update()
  end

  def delete_resource(%Resource{} = resource) do
    Repo.delete(resource)
  end

  def unpublish_resource(%Resource{} = resource) do
    Repo.delete_all(from(gr in GeneratedRecord, where: gr.resource_id == ^resource.id))

    resource
    |> Ecto.Changeset.change(published: false, published_revision: nil)
    |> Repo.update()
  end

  def change_resource(%Resource{} = resource, attrs \\ %{}) do
    Resource.changeset(resource, attrs)
  end

  def resource_needs_regeneration?(%Resource{} = resource) do
    resource.published && resource.published_revision != resource.revision
  end

  @doc """
  Reverts a resource's field definitions to the snapshot saved at publish time.
  """
  def revert_resource_to_published(%Resource{} = resource) do
    case resource.published_schema do
      %{"fields" => snapshot_fields} when is_list(snapshot_fields) ->
        Repo.transaction(fn ->
          # Delete current fields
          Repo.delete_all(from(f in ResourceField, where: f.resource_id == ^resource.id))

          # Restore from snapshot
          for {params, index} <- Enum.with_index(snapshot_fields) do
            attrs = %{
              name: params["name"],
              faker_category: params["faker_category"],
              faker_function: params["faker_function"],
              options: params["options"] || %{}
            }

            %ResourceField{resource_id: resource.id, position: index}
            |> ResourceField.changeset(attrs)
            |> Repo.insert!()
          end

          # Set revision = published_revision (clears stale warning)
          resource
          |> Ecto.Changeset.change(
            revision: resource.published_revision,
            revised_at: DateTime.utc_now(:second)
          )
          |> Repo.update!()
        end)

      _ ->
        {:error, "No published schema snapshot available."}
    end
  end

  # --- Resource Fields ---

  def list_resource_fields(resource_id) do
    from(f in ResourceField,
      where: f.resource_id == ^resource_id,
      order_by: [asc: f.position]
    )
    |> Repo.all()
  end

  def change_resource_field(%ResourceField{} = field, attrs \\ %{}) do
    ResourceField.changeset(field, attrs)
  end

  @doc """
  Saves a batch of field definitions for a resource,
  replacing all existing fields. Bumps revision.
  """
  def save_resource_fields(%Resource{} = resource, field_params_list) do
    Repo.transaction(fn ->
      # Delete all existing fields
      Repo.delete_all(from(f in ResourceField, where: f.resource_id == ^resource.id))

      # Insert new fields
      for {params, index} <- Enum.with_index(field_params_list) do
        %ResourceField{resource_id: resource.id, position: index}
        |> ResourceField.changeset(params)
        |> Repo.insert!()
      end

      # Bump revision
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      resource
      |> Ecto.Changeset.change(revision: resource.revision + 1, revised_at: now)
      |> Repo.update!()
    end)
  end

  # --- Record Generation ---

  def generate_records(%Resource{} = resource) do
    resource = Repo.preload(resource, :fields)
    fields = Enum.sort_by(resource.fields, & &1.position)

    Repo.delete_all(from(gr in GeneratedRecord, where: gr.resource_id == ^resource.id))

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    1..resource.total_records
    |> Enum.chunk_every(100)
    |> Enum.each(fn batch_indices ->
      records =
        Enum.map(batch_indices, fn index ->
          data = generate_single_record(fields)

          %{
            resource_id: resource.id,
            record_index: index,
            data: Map.put(data, "id", index),
            inserted_at: now,
            updated_at: now
          }
        end)

      Repo.insert_all(GeneratedRecord, records)
    end)

    # Snapshot current field definitions for revert capability
    schema_snapshot =
      Enum.map(fields, fn f ->
        %{
          "name" => f.name,
          "faker_category" => f.faker_category,
          "faker_function" => f.faker_function,
          "options" => f.options || %{}
        }
      end)

    resource
    |> Ecto.Changeset.change(
      published: true,
      published_revision: resource.revision,
      published_schema: %{"fields" => schema_snapshot}
    )
    |> Repo.update()
  end

  def generate_single_record(fields) do
    alias Fakr.Mocks.FakerRegistry

    # Separate meta fields from data fields
    {meta_fields, data_fields} =
      Enum.split_with(fields, &String.starts_with?(&1.name, "__group_meta."))

    # Parse group meta
    group_metas =
      for f <- meta_fields, into: %{} do
        group_name = String.replace_prefix(f.name, "__group_meta.", "")
        opts = f.options || %{}

        meta =
          if opts["is_group_array"] == "true" do
            count = resolve_array_count(opts)
            %{is_array: true, count: count}
          else
            %{is_array: false, count: 1}
          end

        {group_name, meta}
      end

    # Generate flat values
    flat =
      Enum.reduce(data_fields, %{}, fn field, acc ->
        options = field.options || %{}
        is_array = options["is_array"] == "true" || options["is_array"] == true

        value =
          if is_array do
            count = resolve_array_count(options)
            Enum.map(1..max(count, 1), fn _ ->
              FakerRegistry.generate(field.faker_category, field.faker_function, options)
            end)
          else
            FakerRegistry.generate(field.faker_category, field.faker_function, options)
          end

        Map.put(acc, field.name, value)
      end)

    # Build nested structure, then apply group array wrapping
    nested = build_nested(flat)
    apply_group_arrays(nested, group_metas, data_fields)
  end

  defp resolve_array_count(opts) do
    mode = opts["array_count_mode"] || opts["count_mode"] || "fixed"

    case mode do
      "range" ->
        min_val = Fakr.Mocks.FakerRegistry.parse_int_public(opts["array_min"] || opts["range_min"], 1)
        max_val = Fakr.Mocks.FakerRegistry.parse_int_public(opts["array_max"] || opts["range_max"], 5)
        Enum.random(max(min_val, 0)..max(max_val, 1))

      _ ->
        Fakr.Mocks.FakerRegistry.parse_int_public(opts["array_count"] || opts["count"], 3)
    end
  end

  defp build_nested(flat_map) do
    Enum.reduce(flat_map, %{}, fn {key, value}, acc ->
      parts = String.split(key, ".", trim: true)
      deep_put(acc, parts, value)
    end)
  end

  defp apply_group_arrays(nested, group_metas, data_fields) do
    alias Fakr.Mocks.FakerRegistry

    Enum.reduce(group_metas, nested, fn {group_name, meta}, acc ->
      if meta.is_array do
        # Find all fields belonging to this group
        group_fields =
          Enum.filter(data_fields, &String.starts_with?(&1.name, group_name <> "."))

        items =
          Enum.map(1..max(meta.count, 1), fn _ ->
            # Generate fresh values for each array item
            Enum.reduce(group_fields, %{}, fn field, item_acc ->
              bare = String.replace_prefix(field.name, group_name <> ".", "")
              opts = field.options || %{}
              is_field_array = opts["is_array"] == "true"

              value =
                if is_field_array do
                  count = resolve_array_count(opts)
                  Enum.map(1..max(count, 1), fn _ ->
                    FakerRegistry.generate(field.faker_category, field.faker_function, opts)
                  end)
                else
                  FakerRegistry.generate(field.faker_category, field.faker_function, opts)
                end

              Map.put(item_acc, bare, value)
            end)
          end)

        Map.put(acc, group_name, items)
      else
        acc
      end
    end)
  end

  defp deep_put(map, [key], value), do: Map.put(map, key, value)

  defp deep_put(map, [head | tail], value) do
    child = Map.get(map, head, %{})
    Map.put(map, head, deep_put(child, tail, value))
  end

  def generate_preview(fields) when is_list(fields) do
    record = generate_single_record(fields)
    Map.put(record, "id", 1)
  end

  # --- Generated Records (API) ---

  @reserved_params ~w(page limit sort order search_column search_term)

  def get_generated_records(resource_id, params \\ %{}) do
    page = parse_int(params["page"], 1)
    limit = parse_int(params["limit"], 10) |> min(100)
    offset = (page - 1) * limit

    base_query = from(gr in GeneratedRecord, where: gr.resource_id == ^resource_id)

    # Apply exact-match filters: ?column=value
    filtered_query =
      params
      |> Map.drop(@reserved_params)
      |> Enum.reduce(base_query, fn {column, value}, query ->
        from(gr in query,
          where: fragment("?->? = ?", gr.data, ^column, ^Jason.encode!(value))
        )
      end)

    # Apply ilike search: ?search_column=name&search_term=john
    filtered_query =
      case {params["search_column"], params["search_term"]} do
        {col, term} when is_binary(col) and col != "" and is_binary(term) and term != "" ->
          pattern = "%#{term}%"

          from(gr in filtered_query,
            where: fragment("?->>? ILIKE ?", gr.data, ^col, ^pattern)
          )

        _ ->
          filtered_query
      end

    # Count after filters
    total = Repo.one(from(gr in filtered_query, select: count()))

    # Apply sorting: ?sort=column&order=asc|desc
    sorted_query =
      case {params["sort"], params["order"]} do
        {col, "desc"} when is_binary(col) and col != "" ->
          from(gr in filtered_query,
            order_by: fragment("?->>? DESC", gr.data, ^col)
          )

        {col, _} when is_binary(col) and col != "" ->
          from(gr in filtered_query,
            order_by: fragment("?->>? ASC", gr.data, ^col)
          )

        _ ->
          from(gr in filtered_query, order_by: [asc: gr.record_index])
      end

    records =
      sorted_query
      |> offset(^offset)
      |> limit(^limit)
      |> Repo.all()

    last_page = max(ceil(total / max(limit, 1)), 1)

    pagination = %{
      "page" => page,
      "limit" => limit,
      "total" => total,
      "current_page" => page,
      "has_next" => page < last_page,
      "has_prev" => page > 1,
      "last_page_no" => last_page
    }

    {records, pagination}
  end

  defp parse_int(nil, default), do: default

  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} when n > 0 -> n
      _ -> default
    end
  end

  defp parse_int(val, _default) when is_integer(val), do: val

  def get_generated_record(resource_id, record_index) do
    Repo.one(
      from(gr in GeneratedRecord,
        where: gr.resource_id == ^resource_id and gr.record_index == ^record_index
      )
    )
  end
end
