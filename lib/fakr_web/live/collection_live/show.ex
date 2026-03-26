defmodule FakrWeb.CollectionLive.Show do
  use FakrWeb, :live_view

  alias Fakr.Mocks
  alias Fakr.Mocks.Resource

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-5xl mx-auto">
        <.link
          navigate={~p"/dashboard"}
          class="text-sm text-blue hover:underline mb-4 inline-block"
        >
          &larr; Back to Dashboard
        </.link>

        <div class="flex items-start justify-between mb-8">
          <div>
            <div class="flex items-center gap-3">
              <h1 class="text-3xl font-bold text-navy">{@collection.name}</h1>
              <span class={[
                "px-2 py-1 text-xs font-medium rounded-full",
                if(any_published?(@collection.resources),
                  do: "bg-teal/20 text-teal",
                  else: "bg-gray-100 text-gray-500"
                )
              ]}>
                {if any_published?(@collection.resources), do: "Live", else: "No published resources"}
              </span>
            </div>
            <p :if={@collection.description} class="mt-2 text-gray-500">{@collection.description}</p>
            <div :if={any_published?(@collection.resources)} class="mt-3 space-y-2">
              <p class="text-sm text-gray-400">
                Public URL:
                <a href={~p"/@#{@username}/#{@collection.slug}"} class="text-blue hover:underline" target="_blank">
                  /@{@username}/{@collection.slug}
                </a>
              </p>
              <div class="flex items-center gap-2">
                <a href={~p"/@#{@username}/#{@collection.slug}"} target="_blank" class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs bg-indigo text-white rounded-lg hover:bg-indigo/90 transition font-medium">
                  <.icon name="hero-globe-alt" class="w-3.5 h-3.5" /> API Docs
                </a>
                <a href={"/@#{@username}/#{@collection.slug}/openapi.json"} target="_blank" class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs bg-code-bg text-mint-light rounded-lg hover:bg-code-bg/80 transition font-medium">
                  <.icon name="hero-document-text" class="w-3.5 h-3.5" /> OpenAPI Spec
                </a>
                <a href={"https://petstore.swagger.io/?url=#{URI.encode(FakrWeb.Endpoint.url() <> "/@#{@username}/#{@collection.slug}/openapi.json")}"} target="_blank" class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs border border-gray-300 text-gray-600 rounded-lg hover:bg-gray-50 transition font-medium">
                  Swagger UI
                </a>
              </div>
            </div>
          </div>
          <button
            phx-click="open_edit_collection"
            class="inline-flex items-center gap-1.5 px-3 py-2 text-sm border border-gray-200 rounded-lg hover:bg-gray-50 transition text-navy/60"
          >
            <.icon name="hero-pencil" class="w-4 h-4" /> Edit
          </button>
        </div>

        <div class="flex items-center justify-between mb-4">
          <h2 class="text-xl font-semibold text-navy">Resources</h2>
          <button
            phx-click="open_resource_modal"
            class="inline-flex items-center px-3 py-2 text-sm bg-indigo text-white rounded-lg hover:bg-indigo/90 transition"
          >
            <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Add Resource
          </button>
        </div>

        <div
          :if={@collection.resources == []}
          class="text-center py-12 bg-white rounded-xl border border-gray-200"
        >
          <.icon name="hero-document-text" class="w-12 h-12 mx-auto text-gray-300" />
          <h3 class="mt-3 text-gray-600">No resources yet</h3>
          <p class="mt-1 text-sm text-gray-400">Add a resource to define your API endpoints.</p>
        </div>

        <div class="space-y-4">
          <div
            :for={resource <- @collection.resources}
            class="bg-white rounded-xl border border-gray-200 p-6"
          >
            <div class="flex items-start justify-between">
              <div>
                <div class="flex items-center gap-2">
                  <h3 class="text-lg font-semibold text-navy">{resource.name}</h3>
                  <span class={[
                    "px-2 py-0.5 text-xs rounded-full",
                    if(resource.published,
                      do: "bg-teal/20 text-teal",
                      else: "bg-gray-100 text-gray-500"
                    )
                  ]}>
                    {if resource.published, do: "Published", else: "Draft"}
                  </span>
                </div>
                <p class="mt-1 text-sm text-gray-400">
                  {length(resource.fields)} field(s) · {resource.total_records} records
                  · Rev. {resource.revision}
                </p>
                <%!-- Stale revision warning --%>
                <div
                  :if={resource.published && resource.published_revision != resource.revision}
                  class="mt-2 flex items-center gap-2 p-2 bg-mint/20 border border-mint rounded-lg"
                >
                  <.icon name="hero-exclamation-triangle" class="w-4 h-4 text-navy shrink-0" />
                  <span class="text-xs text-navy">
                    Schema changed since publish (Rev. {resource.published_revision || "—"} → {resource.revision}). Regenerate to apply.
                  </span>
                </div>
                <div :if={resource.published} class="mt-2 space-y-1">
                  <p class="text-xs font-mono bg-code-bg text-mint-light px-3 py-1.5 rounded inline-block">
                    GET /@{@username}/{@collection.slug}/api/{resource.slug}
                  </p>
                </div>
              </div>
              <div class="flex items-center gap-2 flex-wrap justify-end">
                <button
                  :if={!resource.published && length(resource.fields) > 0}
                  phx-click="publish_resource"
                  phx-value-id={resource.id}
                  class="px-3 py-1.5 text-xs bg-indigo text-white rounded-lg hover:bg-indigo/90 transition font-medium"
                  data-confirm={"Generate #{resource.total_records} mock records and publish?"}
                >
                  Publish
                </button>
                <button
                  :if={resource.published}
                  phx-click="republish_resource"
                  phx-value-id={resource.id}
                  class={[
                    "px-3 py-1.5 text-xs rounded-lg transition font-medium",
                    if(resource.published_revision != resource.revision,
                      do: "bg-mint-light text-navy hover:bg-mint-light/80 ring-2 ring-mint ring-offset-1",
                      else: "bg-gray-100 text-gray-600 hover:bg-gray-200"
                    )
                  ]}
                  data-confirm={"Regenerate #{resource.total_records} mock records?"}
                >
                  Regenerate
                </button>
                <button
                  :if={resource.published}
                  phx-click="unpublish_resource"
                  phx-value-id={resource.id}
                  class="px-3 py-1.5 text-xs border border-red-300 text-red-500 rounded-lg hover:bg-red-50 transition"
                >
                  Unpublish
                </button>
                <.link
                  navigate={~p"/collections/#{@collection.id}/resources/#{resource.id}"}
                  class="p-1.5 text-gray-400 hover:text-blue transition rounded hover:bg-blue/10"
                  title="Edit fields"
                >
                  <.icon name="hero-pencil" class="w-4 h-4" />
                </.link>
                <button
                  phx-click="delete_resource"
                  phx-value-id={resource.id}
                  class="p-1.5 text-gray-400 hover:text-red-500 transition rounded hover:bg-red-50"
                  data-confirm="Delete this resource and all its data?"
                  title="Delete"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- New Resource Modal --%>
      <div :if={@show_resource_modal} class="fixed inset-0 z-50 flex items-center justify-center" phx-window-keydown="close_resource_modal" phx-key="Escape">
        <div class="fixed inset-0 bg-black/40" phx-click="close_resource_modal"></div>
        <div class="relative bg-white rounded-xl shadow-xl p-6 w-full max-w-md mx-4 z-10">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold text-navy">New Resource</h2>
            <button phx-click="close_resource_modal" class="text-navy/30 hover:text-navy/60"><.icon name="hero-x-mark" class="w-5 h-5" /></button>
          </div>
          <.form for={@resource_form} id="new-resource-form" phx-submit="create_resource">
            <div class="space-y-4">
              <.input field={@resource_form[:name]} type="text" label="Resource Name" placeholder="e.g. users, products" required />
              <.input field={@resource_form[:total_records]} type="number" label="Total Records" min="1" max="1000" />
            </div>
            <div class="mt-6 flex items-center gap-3">
              <button type="submit" class="px-4 py-2 bg-indigo text-white text-sm rounded-lg hover:bg-violet transition font-medium">Create</button>
              <button type="button" phx-click="close_resource_modal" class="text-sm text-navy/40 hover:text-navy/60">Cancel</button>
            </div>
          </.form>
        </div>
      </div>

      <%!-- Edit Collection Modal --%>
      <div :if={@show_edit_collection} class="fixed inset-0 z-50 flex items-center justify-center" phx-window-keydown="close_edit_collection" phx-key="Escape">
        <div class="fixed inset-0 bg-black/40" phx-click="close_edit_collection"></div>
        <div class="relative bg-white rounded-xl shadow-xl p-6 w-full max-w-md mx-4 z-10">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold text-navy">Edit Collection</h2>
            <button phx-click="close_edit_collection" class="text-navy/30 hover:text-navy/60"><.icon name="hero-x-mark" class="w-5 h-5" /></button>
          </div>
          <.form for={@collection_form} id="edit-collection-form" phx-submit="update_collection">
            <div class="space-y-4">
              <.input field={@collection_form[:name]} type="text" label="Name" required />
              <.input field={@collection_form[:description]} type="textarea" label="Description" />
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="hidden" name="collection[explorable]" value="false" />
                <input type="checkbox" name="collection[explorable]" value="true" checked={Phoenix.HTML.Form.input_value(@collection_form, :explorable) == true || Phoenix.HTML.Form.input_value(@collection_form, :explorable) == "true"} class="checkbox checkbox-sm" />
                <span class="text-sm text-navy/70">Show in Explore page</span>
              </label>
            </div>
            <div class="mt-6 flex items-center gap-3">
              <button type="submit" class="px-4 py-2 bg-indigo text-white text-sm rounded-lg hover:bg-violet transition font-medium">Save</button>
              <button type="button" phx-click="close_edit_collection" class="text-sm text-navy/40 hover:text-navy/60">Cancel</button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_scope.user
    collection = Mocks.get_user_collection!(user.id, id)

    {:ok,
     socket
     |> assign(
       collection: collection,
       username: user.username,
       page_title: collection.name,
       show_resource_modal: false,
       resource_form: new_resource_form(),
       show_edit_collection: false,
       collection_form: to_form(Mocks.change_collection(collection), as: "collection")
     )}
  end

  @impl true
  def handle_event("open_resource_modal", _params, socket) do
    {:noreply, assign(socket, show_resource_modal: true, resource_form: new_resource_form())}
  end

  def handle_event("close_resource_modal", _params, socket) do
    {:noreply, assign(socket, show_resource_modal: false)}
  end

  def handle_event("open_edit_collection", _params, socket) do
    form = to_form(Mocks.change_collection(socket.assigns.collection), as: "collection")
    {:noreply, assign(socket, show_edit_collection: true, collection_form: form)}
  end

  def handle_event("close_edit_collection", _params, socket) do
    {:noreply, assign(socket, show_edit_collection: false)}
  end

  def handle_event("update_collection", %{"collection" => params}, socket) do
    case Mocks.update_collection(socket.assigns.collection, params) do
      {:ok, _} ->
        collection = Mocks.get_user_collection!(socket.assigns.current_scope.user.id, socket.assigns.collection.id)
        {:noreply, socket |> assign(collection: collection, show_edit_collection: false) |> put_flash(:info, "Collection updated.")}
      {:error, changeset} ->
        {:noreply, assign(socket, collection_form: to_form(changeset, as: "collection"))}
    end
  end

  def handle_event("create_resource", %{"resource" => params}, socket) do
    case Mocks.create_resource(socket.assigns.collection, params) do
      {:ok, resource} ->
        {:noreply,
         socket
         |> assign(show_resource_modal: false)
         |> reload_collection("\"#{resource.name}\" created!")
         |> push_navigate(to: ~p"/collections/#{socket.assigns.collection.id}/resources/#{resource.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, resource_form: to_form(changeset, as: "resource"))}
    end
  end

  def handle_event("publish_resource", %{"id" => id}, socket) do
    resource = Mocks.get_resource!(String.to_integer(id))
    Mocks.generate_records(resource)
    {:noreply, reload_collection(socket, "\"#{resource.name}\" published!")}
  end

  def handle_event("republish_resource", %{"id" => id}, socket) do
    resource = Mocks.get_resource!(String.to_integer(id))
    Mocks.generate_records(resource)
    {:noreply, reload_collection(socket, "\"#{resource.name}\" regenerated!")}
  end

  def handle_event("unpublish_resource", %{"id" => id}, socket) do
    resource = Mocks.get_resource!(String.to_integer(id))
    Mocks.unpublish_resource(resource)
    {:noreply, reload_collection(socket, "\"#{resource.name}\" unpublished.")}
  end

  def handle_event("delete_resource", %{"id" => id}, socket) do
    resource = Mocks.get_resource!(String.to_integer(id))
    {:ok, _} = Mocks.delete_resource(resource)
    {:noreply, reload_collection(socket, "Resource deleted.")}
  end

  defp reload_collection(socket, flash_msg) do
    collection =
      Mocks.get_user_collection!(
        socket.assigns.current_scope.user.id,
        socket.assigns.collection.id
      )

    socket
    |> assign(collection: collection)
    |> put_flash(:info, flash_msg)
  end

  defp new_resource_form do
    to_form(Mocks.change_resource(%Resource{}), as: "resource")
  end

  defp any_published?(resources), do: Enum.any?(resources, & &1.published)
end
