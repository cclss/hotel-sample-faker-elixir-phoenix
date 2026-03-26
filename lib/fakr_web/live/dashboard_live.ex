defmodule FakrWeb.DashboardLive do
  use FakrWeb, :live_view

  alias Fakr.Mocks
  alias Fakr.Mocks.Collection

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-5xl mx-auto">
        <div class="flex items-center justify-between mb-8">
          <div>
            <h1 class="text-3xl font-bold text-navy">My Collections</h1>
            <p class="text-gray-500 mt-1">Manage your Faker API collections</p>
          </div>
          <button
            phx-click="open_new_collection"
            class="inline-flex items-center px-4 py-2 bg-indigo text-white rounded-lg hover:bg-violet transition font-medium"
          >
            <.icon name="hero-plus" class="w-5 h-5 mr-2" /> New Collection
          </button>
        </div>

        <div :if={@collections == []} class="text-center py-16 bg-white rounded-xl border border-gray-200">
          <.icon name="hero-folder-open" class="w-16 h-16 mx-auto text-gray-300" />
          <h3 class="mt-4 text-lg font-medium text-gray-600">No collections yet</h3>
          <p class="mt-2 text-gray-400">Create your first Faker API collection to get started.</p>
          <button phx-click="open_new_collection" class="inline-flex items-center mt-6 px-4 py-2 bg-indigo text-white rounded-lg hover:bg-violet transition">
            Create Collection
          </button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <.link
            :for={collection <- @collections}
            navigate={~p"/collections/#{collection.id}"}
            class="block bg-white rounded-xl border border-gray-200 p-6 hover:shadow-md hover:border-indigo/30 transition"
          >
            <div class="flex items-start justify-between">
              <h3 class="text-lg font-semibold text-navy">{collection.name}</h3>
              <span class={[
                "px-2 py-1 text-xs font-medium rounded-full",
                if(Enum.any?(collection.resources, & &1.published), do: "bg-teal/20 text-teal", else: "bg-gray-100 text-gray-500")
              ]}>
                {if Enum.any?(collection.resources, & &1.published), do: "Live", else: "Draft"}
              </span>
            </div>
            <p :if={collection.description} class="mt-2 text-sm text-gray-500 line-clamp-2">{collection.description}</p>
            <div class="mt-4 flex items-center text-sm text-gray-400">
              <.icon name="hero-cube" class="w-4 h-4 mr-1" />
              {length(collection.resources)} resource(s)
            </div>
          </.link>
        </div>
      </div>

      <%!-- New Collection Modal --%>
      <div :if={@show_new_collection} class="fixed inset-0 z-50 flex items-center justify-center" phx-window-keydown="close_new_collection" phx-key="Escape">
        <div class="fixed inset-0 bg-black/40" phx-click="close_new_collection"></div>
        <div class="relative bg-white rounded-xl shadow-xl p-6 w-full max-w-md mx-4 z-10">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold text-navy">New Collection</h2>
            <button phx-click="close_new_collection" class="text-navy/30 hover:text-navy/60"><.icon name="hero-x-mark" class="w-5 h-5" /></button>
          </div>
          <.form for={@collection_form} id="new-collection-form" phx-submit="create_collection">
            <div class="space-y-4">
              <.input field={@collection_form[:name]} type="text" label="Collection Name" placeholder="e.g. E-Commerce API" required />
              <.input field={@collection_form[:description]} type="textarea" label="Description" placeholder="Describe what this collection provides..." />
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="hidden" name="collection[explorable]" value="false" />
                <input type="checkbox" name="collection[explorable]" value="true" class="checkbox checkbox-sm" />
                <span class="text-sm text-navy/70">Show in Explore page</span>
              </label>
            </div>
            <div class="mt-6 flex items-center gap-3">
              <button type="submit" class="px-4 py-2 bg-indigo text-white text-sm rounded-lg hover:bg-violet transition font-medium">Create</button>
              <button type="button" phx-click="close_new_collection" class="text-sm text-navy/40 hover:text-navy/60">Cancel</button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    collections = Mocks.list_user_collections(user.id)

    {:ok,
     assign(socket,
       collections: collections,
       show_new_collection: false,
       collection_form: to_form(Mocks.change_collection(%Collection{}), as: "collection"),
       page_title: "Dashboard"
     )}
  end

  @impl true
  def handle_event("open_new_collection", _params, socket) do
    {:noreply, assign(socket, show_new_collection: true, collection_form: to_form(Mocks.change_collection(%Collection{}), as: "collection"))}
  end

  def handle_event("close_new_collection", _params, socket) do
    {:noreply, assign(socket, show_new_collection: false)}
  end

  def handle_event("create_collection", %{"collection" => params}, socket) do
    user = socket.assigns.current_scope.user

    case Mocks.create_collection(user, params) do
      {:ok, collection} ->
        {:noreply,
         socket
         |> assign(show_new_collection: false)
         |> put_flash(:info, "Collection created!")
         |> push_navigate(to: ~p"/collections/#{collection.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, collection_form: to_form(changeset, as: "collection"))}
    end
  end
end
