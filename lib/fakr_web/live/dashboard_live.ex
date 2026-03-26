defmodule FakrWeb.DashboardLive do
  use FakrWeb, :live_view

  alias Fakr.Mocks

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-5xl mx-auto">
        <div class="flex items-center justify-between mb-8">
          <div>
            <h1 class="text-3xl font-bold text-peppercorn">My Collections</h1>
            <p class="text-gray-500 mt-1">Manage your Faker API collections</p>
          </div>
          <.link
            navigate={~p"/collections/new"}
            class="inline-flex items-center px-4 py-2 bg-cypress text-white rounded-lg hover:bg-cypress/90 transition font-medium"
          >
            <.icon name="hero-plus" class="w-5 h-5 mr-2" /> New Collection
          </.link>
        </div>

        <div
          :if={@collections == []}
          class="text-center py-16 bg-white rounded-xl border border-smoke"
        >
          <.icon name="hero-folder-open" class="w-16 h-16 mx-auto text-gray-300" />
          <h3 class="mt-4 text-lg font-medium text-gray-600">No collections yet</h3>
          <p class="mt-2 text-gray-400">Create your first Faker API collection to get started.</p>
          <.link
            navigate={~p"/collections/new"}
            class="inline-flex items-center mt-6 px-4 py-2 bg-cypress text-white rounded-lg hover:bg-cypress/90 transition"
          >
            Create Collection
          </.link>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div
            :for={collection <- @collections}
            class="bg-white rounded-xl border border-smoke p-6 hover:shadow-md transition"
          >
            <div class="flex items-start justify-between">
              <h3 class="text-lg font-semibold text-peppercorn">{collection.name}</h3>
              <span class={[
                "px-2 py-1 text-xs font-medium rounded-full",
                if(Enum.any?(collection.resources, & &1.published),
                  do: "bg-green-100 text-green-700",
                  else: "bg-gray-100 text-gray-500"
                )
              ]}>
                {if Enum.any?(collection.resources, & &1.published), do: "Live", else: "Draft"}
              </span>
            </div>
            <p :if={collection.description} class="mt-2 text-sm text-gray-500 line-clamp-2">
              {collection.description}
            </p>
            <div class="mt-4 flex items-center text-sm text-gray-400">
              <.icon name="hero-cube" class="w-4 h-4 mr-1" />
              {length(collection.resources)} resource(s)
            </div>
            <div class="mt-4 flex items-center gap-2">
              <.link
                navigate={~p"/collections/#{collection.id}"}
                class="text-sm text-cypress hover:underline font-medium"
              >
                Manage
              </.link>
              <span class="text-gray-300">|</span>
              <.link
                :if={Enum.any?(collection.resources, & &1.published)}
                navigate={~p"/@#{@current_scope.user.username}/#{collection.slug}"}
                class="text-sm text-gray-500 hover:underline"
              >
                View Public Page
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    collections = Mocks.list_user_collections(user.id)
    {:ok, assign(socket, collections: collections, page_title: "Dashboard")}
  end
end
