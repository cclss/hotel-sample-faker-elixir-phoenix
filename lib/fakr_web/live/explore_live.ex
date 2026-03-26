defmodule FakrWeb.ExploreLive do
  use FakrWeb, :live_view

  alias Fakr.Mocks

  @per_page 12

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-5xl mx-auto">
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-peppercorn">Explore</h1>
          <p class="text-gray-500 mt-1">Discover public Faker API collections</p>
        </div>

        <div :if={@collections == []} class="text-center py-16 bg-white rounded-xl border border-smoke">
          <.icon name="hero-globe-alt" class="w-16 h-16 mx-auto text-gray-300" />
          <h3 class="mt-4 text-lg font-medium text-gray-600">No public collections yet</h3>
          <p class="mt-2 text-gray-400">Collections will appear here when owners make them explorable.</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div :for={collection <- @collections} class="bg-white rounded-xl border border-smoke p-6 hover:shadow-md transition">
            <div class="flex items-start justify-between mb-2">
              <h3 class="text-lg font-semibold text-peppercorn">{collection.name}</h3>
              <span class="text-xs text-gray-400">@{collection.user.username}</span>
            </div>
            <p :if={collection.description} class="text-sm text-gray-500 line-clamp-2 mb-3">{collection.description}</p>
            <div class="flex items-center gap-3 text-sm text-gray-400 mb-4">
              <span class="flex items-center gap-1">
                <.icon name="hero-cube" class="w-4 h-4" />
                {length(Enum.filter(collection.resources, & &1.published))} resource(s)
              </span>
            </div>
            <.link
              navigate={~p"/@#{collection.user.username}/#{collection.slug}"}
              class="text-sm text-cypress hover:underline font-medium"
            >
              View Collection &rarr;
            </.link>
          </div>
        </div>

        <div :if={@has_more} class="text-center mt-8">
          <button phx-click="load_more" class="px-6 py-2 bg-smoke text-peppercorn rounded-lg hover:bg-smoke-dark transition text-sm font-medium">
            Load more
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    collections = Mocks.list_explorable_collections(limit: @per_page)
    total = Mocks.count_explorable_collections()

    {:ok,
     assign(socket,
       collections: collections,
       page: 1,
       has_more: length(collections) < total,
       page_title: "Explore"
     )}
  end

  @impl true
  def handle_event("load_more", _params, socket) do
    next_page = socket.assigns.page + 1
    offset = next_page * @per_page

    more = Mocks.list_explorable_collections(limit: @per_page, offset: offset)
    total = Mocks.count_explorable_collections()
    all = socket.assigns.collections ++ more

    {:noreply,
     assign(socket,
       collections: all,
       page: next_page,
       has_more: length(all) < total
     )}
  end
end
