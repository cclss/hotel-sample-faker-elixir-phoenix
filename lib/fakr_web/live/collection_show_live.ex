defmodule FakrWeb.CollectionShowLive do
  use FakrWeb, :live_view

  alias Fakr.Accounts
  alias Fakr.Mocks

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto">
        <div class="flex gap-8">
          <%!-- Sidebar --%>
          <nav class="w-56 shrink-0 hidden lg:block">
            <div class="sticky top-24">
              <h3 class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-3">
                Resources
              </h3>
              <ul class="space-y-1">
                <li :for={resource <- @resources}>
                  <button
                    phx-click="select_resource"
                    phx-value-id={resource.id}
                    class={[
                      "w-full text-left px-3 py-2 rounded-lg text-sm transition",
                      if(@selected_resource && @selected_resource.id == resource.id,
                        do: "bg-cypress/10 text-cypress font-medium border-l-2 border-cypress",
                        else: "text-gray-600 hover:bg-smoke"
                      )
                    ]}
                  >
                    {resource.name}
                  </button>
                </li>
              </ul>
            </div>
          </nav>

          <%!-- Main Content --%>
          <div class="flex-1 min-w-0">
            <div class="mb-8">
              <h1 class="text-3xl font-bold text-peppercorn">{@collection.name}</h1>
              <p class="text-gray-500 mt-1">by @{@username}</p>
              <p :if={@collection.description} class="text-gray-500 mt-2">
                {@collection.description}
              </p>
              <div class="mt-3 flex items-center gap-3">
                <a
                  href={"/@#{@username}/#{@collection.slug}/openapi.json"}
                  target="_blank"
                  class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs bg-peppercorn text-cavendish rounded-lg hover:bg-peppercorn/80 transition font-medium"
                >
                  <.icon name="hero-document-text" class="w-3.5 h-3.5" /> OpenAPI Spec
                </a>
                <a
                  href={"https://petstore.swagger.io/?url=#{URI.encode(@base_url <> "/@#{@username}/#{@collection.slug}/openapi.json")}"}
                  target="_blank"
                  class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs border border-gray-300 text-gray-600 rounded-lg hover:bg-gray-50 transition font-medium"
                >
                  Swagger UI
                </a>
              </div>
            </div>

            <%!-- Mobile Resource Selector --%>
            <div class="lg:hidden mb-6">
              <select phx-change="select_resource_mobile" class="select select-bordered w-full">
                <option
                  :for={resource <- @resources}
                  value={resource.id}
                  selected={@selected_resource && @selected_resource.id == resource.id}
                >
                  {resource.name}
                </option>
              </select>
            </div>

            <div :if={@selected_resource} class="space-y-6">
              <%!-- Schema --%>
              <div class="bg-white rounded-xl border border-smoke p-6">
                <h2 class="text-xl font-semibold text-peppercorn mb-4">{@selected_resource.name}</h2>
                <h3 class="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-2">
                  Schema
                </h3>
                <div class="overflow-x-auto">
                  <table class="w-full text-sm">
                    <thead>
                      <tr class="border-b border-smoke">
                        <th class="text-left py-2 px-3 font-medium text-gray-500">Field</th>
                        <th class="text-left py-2 px-3 font-medium text-gray-500">Generator</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr class="border-b border-smoke/50">
                        <td class="py-2 px-3 font-mono text-peppercorn">id</td>
                        <td class="py-2 px-3 text-gray-400">Auto-increment integer</td>
                      </tr>
                      <tr :for={field <- @selected_resource.fields} class="border-b border-smoke/50">
                        <td class="py-2 px-3 font-mono text-peppercorn">{field.name}</td>
                        <td class="py-2 px-3 text-gray-400">
                          {field.faker_category}.{field.faker_function}
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <%!-- API Endpoints --%>
              <div class="bg-white rounded-xl border border-smoke p-6">
                <h3 class="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
                  Endpoints
                </h3>
                <div class="space-y-3">
                  <.endpoint_card
                    path={"/@#{@username}/#{@collection.slug}/api/#{@selected_resource.slug}"}
                    base_url={@base_url}
                    description={"List all #{Inflex.pluralize(@selected_resource.name)} with pagination"}
                    hint="Query params: ?page=1&limit=10"
                  />
                  <.endpoint_card
                    path={"/@#{@username}/#{@collection.slug}/api/#{@selected_resource.slug}/:id"}
                    base_url={@base_url}
                    description={"Get a single #{Inflex.singularize(@selected_resource.name)} by ID"}
                  />
                </div>
              </div>

              <%!-- Query Parameters Reference --%>
              <div class="bg-white rounded-xl border border-smoke p-6">
                <h3 class="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
                  Query Parameters
                </h3>
                <div class="overflow-x-auto">
                  <table class="w-full text-sm">
                    <thead>
                      <tr class="border-b border-smoke text-left">
                        <th class="py-2 px-2 font-medium text-gray-500">Param</th>
                        <th class="py-2 px-2 font-medium text-gray-500">Description</th>
                      </tr>
                    </thead>
                    <tbody class="text-gray-600">
                      <tr class="border-b border-smoke/50"><td class="py-1.5 px-2 font-mono text-xs text-cypress">page</td><td class="py-1.5 px-2">Page number (default: 1)</td></tr>
                      <tr class="border-b border-smoke/50"><td class="py-1.5 px-2 font-mono text-xs text-cypress">limit</td><td class="py-1.5 px-2">Items per page (default: 10, max: 100)</td></tr>
                      <tr class="border-b border-smoke/50"><td class="py-1.5 px-2 font-mono text-xs text-cypress">sort</td><td class="py-1.5 px-2">Sort by field name</td></tr>
                      <tr class="border-b border-smoke/50"><td class="py-1.5 px-2 font-mono text-xs text-cypress">order</td><td class="py-1.5 px-2">asc or desc (default: asc)</td></tr>
                      <tr class="border-b border-smoke/50"><td class="py-1.5 px-2 font-mono text-xs text-cypress"><em>column</em>=value</td><td class="py-1.5 px-2">Exact match filter on any field</td></tr>
                      <tr class="border-b border-smoke/50"><td class="py-1.5 px-2 font-mono text-xs text-cypress">search_column</td><td class="py-1.5 px-2">Field name for text search</td></tr>
                      <tr class="border-b border-smoke/50"><td class="py-1.5 px-2 font-mono text-xs text-cypress">search_term</td><td class="py-1.5 px-2">Search keyword (case-insensitive)</td></tr>
                      <tr class="border-b border-smoke/50"><td class="py-1.5 px-2 font-mono text-xs text-cypress">delay</td><td class="py-1.5 px-2">Response delay in ms (max: 10000)</td></tr>
                      <tr><td class="py-1.5 px-2 font-mono text-xs text-cypress">status</td><td class="py-1.5 px-2">Simulate error (e.g. 500, 401, 403)</td></tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <%!-- Code Snippets --%>
              <div class="bg-white rounded-xl border border-smoke p-6">
                <h3 class="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
                  Code Snippets
                </h3>
                <div class="space-y-3">
                  <div>
                    <div class="flex items-center justify-between mb-1">
                      <span class="text-xs font-medium text-gray-500">cURL</span>
                      <button
                        phx-click={JS.dispatch("phx:copy", detail: %{text: snippet_curl(assigns)})}
                        class="text-xs text-gray-400 hover:text-cypress"
                      >copy</button>
                    </div>
                    <pre class="bg-peppercorn text-green-400 p-3 rounded-lg text-xs font-mono overflow-x-auto">{snippet_curl(assigns)}</pre>
                  </div>
                  <div>
                    <div class="flex items-center justify-between mb-1">
                      <span class="text-xs font-medium text-gray-500">JavaScript (fetch)</span>
                      <button
                        phx-click={JS.dispatch("phx:copy", detail: %{text: snippet_fetch(assigns)})}
                        class="text-xs text-gray-400 hover:text-cypress"
                      >copy</button>
                    </div>
                    <pre class="bg-peppercorn text-green-400 p-3 rounded-lg text-xs font-mono overflow-x-auto whitespace-pre-wrap">{snippet_fetch(assigns)}</pre>
                  </div>
                  <div>
                    <div class="flex items-center justify-between mb-1">
                      <span class="text-xs font-medium text-gray-500">Python (requests)</span>
                      <button
                        phx-click={JS.dispatch("phx:copy", detail: %{text: snippet_python(assigns)})}
                        class="text-xs text-gray-400 hover:text-cypress"
                      >copy</button>
                    </div>
                    <pre class="bg-peppercorn text-green-400 p-3 rounded-lg text-xs font-mono overflow-x-auto whitespace-pre-wrap">{snippet_python(assigns)}</pre>
                  </div>
                </div>
              </div>

              <%!-- Try It Panel --%>
              <div class="bg-white rounded-xl border border-smoke p-6">
                <h3 class="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-3">
                  Try It
                </h3>

                <%!-- Endpoint Selector Tabs --%>
                <div class="flex border-b border-smoke mb-4">
                  <button
                    phx-click="set_try_mode"
                    phx-value-mode="list"
                    class={[
                      "px-4 py-2 text-sm font-medium border-b-2 transition -mb-px",
                      if(@try_mode == "list",
                        do: "border-cypress text-cypress",
                        else: "border-transparent text-gray-400 hover:text-gray-600"
                      )
                    ]}
                  >
                    List
                  </button>
                  <button
                    phx-click="set_try_mode"
                    phx-value-mode="detail"
                    class={[
                      "px-4 py-2 text-sm font-medium border-b-2 transition -mb-px",
                      if(@try_mode == "detail",
                        do: "border-cypress text-cypress",
                        else: "border-transparent text-gray-400 hover:text-gray-600"
                      )
                    ]}
                  >
                    Detail
                  </button>
                </div>

                <%!-- Request URL Preview --%>
                <div class="bg-peppercorn rounded-lg px-3 py-2 mb-4 space-y-1">
                  <div class="flex items-center gap-2 font-mono text-sm">
                    <span class="text-xs font-bold text-cavendish bg-cavendish/20 px-1.5 py-0.5 rounded">GET</span>
                    <span class="text-green-400 truncate flex-1">
                      /@{@username}/{@collection.slug}/api/{@selected_resource.slug}<%= if @try_mode == "list" do %>?page={@try_page}&limit={@try_limit}<% else %>/{@try_detail_id}<% end %>
                    </span>
                    <button
                      phx-click={JS.dispatch("phx:copy", detail: %{text: try_full_url(assigns)})}
                      class="text-gray-500 hover:text-cavendish transition shrink-0"
                      title="Copy full URL"
                    >
                      <.icon name="hero-clipboard" class="w-4 h-4" />
                    </button>
                  </div>
                  <p class="text-[11px] text-gray-500 font-mono truncate">{try_full_url(assigns)}</p>
                </div>

                <%!-- Controls --%>
                <div class="flex items-end gap-3 mb-4 flex-wrap">
                  <%= if @try_mode == "list" do %>
                    <div>
                      <label class="block text-xs text-gray-500 mb-1">Page</label>
                      <input
                        type="number"
                        value={@try_page}
                        phx-change="update_try_params"
                        name="page"
                        min="1"
                        class="input input-bordered input-sm w-20"
                      />
                    </div>
                    <div>
                      <label class="block text-xs text-gray-500 mb-1">Limit</label>
                      <input
                        type="number"
                        value={@try_limit}
                        phx-change="update_try_params"
                        name="limit"
                        min="1"
                        max="100"
                        class="input input-bordered input-sm w-20"
                      />
                    </div>
                  <% else %>
                    <div>
                      <label class="block text-xs text-gray-500 mb-1">Record ID</label>
                      <input
                        type="number"
                        value={@try_detail_id}
                        phx-change="update_try_params"
                        name="detail_id"
                        min="1"
                        class="input input-bordered input-sm w-24"
                      />
                    </div>
                  <% end %>
                  <button
                    phx-click="try_api"
                    class="px-4 py-1.5 bg-cypress text-white text-sm rounded-lg hover:bg-cypress/90 transition font-medium"
                  >
                    Send Request
                  </button>
                </div>

                <%!-- Response --%>
                <div :if={@try_response} class="mt-4">
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-xs font-medium text-gray-500">Response</span>
                    <span class={[
                      "text-xs font-mono",
                      if(@try_status == 200, do: "text-green-600", else: "text-red-500")
                    ]}>
                      {if @try_status == 200, do: "200 OK", else: "404 Not Found"}
                    </span>
                  </div>
                  <pre class="bg-peppercorn text-green-400 p-4 rounded-lg overflow-x-auto text-sm font-mono whitespace-pre-wrap max-h-[500px] overflow-y-auto"><code>{@try_response}</code></pre>

                  <%!-- Quick Detail Links from List Response --%>
                  <div :if={@try_mode == "list" && @list_record_ids != []} class="mt-3 border-t border-smoke pt-3">
                    <p class="text-xs text-gray-500 mb-2">Quick view detail:</p>
                    <div class="flex flex-wrap gap-1.5">
                      <button
                        :for={record_id <- @list_record_ids}
                        phx-click="try_detail_quick"
                        phx-value-id={record_id}
                        class="px-2.5 py-1 text-xs font-mono bg-smoke hover:bg-cypress hover:text-white text-peppercorn rounded transition cursor-pointer"
                      >
                        /{record_id}
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div :if={@selected_resource == nil} class="text-center py-16 text-gray-400">
              <p>Select a resource from the sidebar to view its details.</p>
            </div>

            <%!-- Live Activity --%>
            <div class="mt-8 bg-white rounded-xl border border-smoke p-6">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-sm font-semibold text-gray-500 uppercase tracking-wider">
                  Live Activity
                </h3>
                <div class="flex items-center gap-2">
                  <form phx-change="update_activity_filter" class="flex items-center gap-1.5">
                    <label class="text-xs text-gray-400">Client filter:</label>
                    <input
                      type="text"
                      value={@activity_client_filter}
                      name="client_filter"
                      placeholder="my-app"
                      phx-debounce="300"
                      class="input input-bordered input-xs w-28"
                    />
                  </form>
                  <span class="flex items-center gap-1 text-xs text-green-500">
                    <span class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                    live
                  </span>
                </div>
              </div>

              <p class="text-xs text-gray-400 mb-3">
                Add <code class="bg-smoke px-1 rounded">?_client=my-app</code> to your API calls to filter logs here.
              </p>

              <div :if={@activity_log == []} class="text-center py-6 text-gray-400 text-sm">
                No requests yet. API calls will appear here in real-time.
              </div>

              <div :if={@activity_log != []} class="space-y-1 max-h-80 overflow-y-auto">
                <div
                  :for={entry <- @activity_log}
                  class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-smoke/50 transition text-sm group cursor-pointer"
                  phx-click="toggle_activity_detail"
                  phx-value-id={entry.id}
                >
                  <span class={[
                    "w-10 text-xs font-mono font-bold text-center",
                    cond do
                      entry.status < 300 -> "text-green-600"
                      entry.status < 400 -> "text-yellow-600"
                      true -> "text-red-500"
                    end
                  ]}>
                    {entry.status}
                  </span>
                  <span class="text-xs font-mono text-gray-500 w-12 text-right">{entry.duration_ms}ms</span>
                  <span class="text-xs font-mono text-peppercorn flex-1 truncate">{entry.method} {entry.path}</span>
                  <span :if={entry.client} class="text-[10px] bg-blue-100 text-blue-600 px-1.5 rounded">{entry.client}</span>
                  <span class="text-[10px] text-gray-300">{format_time(entry.timestamp)}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- ═══ Request Detail Modal ═══ --%>
      <div
        :if={@activity_detail}
        class="fixed inset-0 z-50 flex items-center justify-center"
        phx-window-keydown="close_activity_detail"
        phx-key="Escape"
      >
        <div class="fixed inset-0 bg-black/50" phx-click="close_activity_detail"></div>
        <div class="relative bg-white rounded-xl shadow-xl w-full max-w-2xl mx-4 z-10 max-h-[85vh] overflow-y-auto">
          <%!-- Header --%>
          <div class="sticky top-0 bg-white border-b border-smoke px-6 py-4 flex items-center justify-between rounded-t-xl">
            <div class="flex items-center gap-3">
              <span class={[
                "px-2 py-1 text-sm font-bold rounded",
                cond do
                  @activity_detail.status < 300 -> "bg-green-100 text-green-700"
                  @activity_detail.status < 400 -> "bg-yellow-100 text-yellow-700"
                  true -> "bg-red-100 text-red-700"
                end
              ]}>
                {@activity_detail.status}
              </span>
              <span class="font-mono text-sm text-peppercorn font-semibold">{@activity_detail.method}</span>
              <span class="text-xs text-gray-400">{@activity_detail.duration_ms}ms</span>
            </div>
            <button phx-click="close_activity_detail" class="text-gray-400 hover:text-gray-600">
              <.icon name="hero-x-mark" class="w-5 h-5" />
            </button>
          </div>

          <div class="px-6 py-4 space-y-5">
            <%!-- URL --%>
            <div>
              <h4 class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">URL</h4>
              <code class="text-sm font-mono text-peppercorn break-all">
                {@activity_detail.path}<%= if @activity_detail.query_string != "" do %>?{@activity_detail.query_string}<% end %>
              </code>
            </div>

            <%!-- Timestamp + Client --%>
            <div class="flex items-center gap-4 text-sm text-gray-500">
              <span>{@activity_detail.timestamp}</span>
              <span :if={@activity_detail.client} class="text-xs bg-blue-100 text-blue-600 px-2 py-0.5 rounded">
                client: {@activity_detail.client}
              </span>
            </div>

            <%!-- Request Headers --%>
            <div>
              <h4 class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">Request Headers</h4>
              <div class="bg-smoke/50 rounded-lg p-3 overflow-x-auto">
                <table class="text-xs font-mono w-full">
                  <tbody>
                    <tr :for={{name, value} <- @activity_detail.request_headers || []} class="border-b border-smoke/50 last:border-0">
                      <td class="py-1 pr-3 text-gray-500 whitespace-nowrap align-top">{name}</td>
                      <td class="py-1 text-peppercorn break-all">{value}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <%!-- Response Headers --%>
            <div>
              <h4 class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">Response Headers</h4>
              <div class="bg-smoke/50 rounded-lg p-3 overflow-x-auto">
                <table class="text-xs font-mono w-full">
                  <tbody>
                    <tr :for={{name, value} <- @activity_detail.response_headers || []} class="border-b border-smoke/50 last:border-0">
                      <td class="py-1 pr-3 text-gray-500 whitespace-nowrap align-top">{name}</td>
                      <td class="py-1 text-peppercorn break-all">{value}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <%!-- Response Body --%>
            <div>
              <h4 class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">Response Body</h4>
              <pre class="bg-peppercorn text-green-400 p-4 rounded-lg overflow-x-auto text-xs font-mono whitespace-pre-wrap max-h-72 overflow-y-auto"><code>{@activity_detail.response_body || "(empty)"}</code></pre>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"username" => username, "collection_slug" => slug}, _session, socket) do
    user = Accounts.get_user_by_username!(username)
    collection = Mocks.get_collection_by_slug!(user.id, slug)

    published_resources = Enum.filter(collection.resources, & &1.published)

    if published_resources == [] do
      {:ok,
       socket |> put_flash(:error, "This collection has no published resources.") |> redirect(to: ~p"/")}
    else
      resources = published_resources
      selected = List.first(resources)
      collection_key = "#{username}/#{slug}"

      # Subscribe to live API activity
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Fakr.PubSub, "api_log:#{collection_key}")
      end

      existing_log = Fakr.ApiLogger.get_requests(collection_key)

      {:ok,
       socket
       |> assign(
         collection: collection,
         resources: resources,
         selected_resource: selected,
         username: username,
         collection_key: collection_key,
         try_mode: "list",
         try_page: 1,
         try_limit: 10,
         try_detail_id: 1,
         try_response: nil,
         try_status: 200,
         list_record_ids: [],
         base_url: FakrWeb.Endpoint.url(),
         activity_log: existing_log,
         activity_client_filter: "",
         activity_detail: nil,
         page_title: "#{collection.name} — @#{username}"
       )}
    end
  end

  @impl true
  def handle_event("select_resource", %{"id" => id}, socket) do
    resource = Enum.find(socket.assigns.resources, &(&1.id == String.to_integer(id)))

    {:noreply,
     assign(socket,
       selected_resource: resource,
       try_response: nil,
       try_status: 200,
       list_record_ids: [],
       try_mode: "list",
       try_detail_id: 1
     )}
  end

  def handle_event("select_resource_mobile", params, socket) do
    id = params["_target"] |> List.first() |> then(fn _ -> params end) |> Map.values() |> List.first()

    case id do
      id when is_binary(id) -> handle_event("select_resource", %{"id" => id}, socket)
      _ -> {:noreply, socket}
    end
  end

  def handle_event("set_try_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, try_mode: mode, try_response: nil, try_status: 200, list_record_ids: [])}
  end

  def handle_event("update_activity_filter", %{"client_filter" => filter}, socket) do
    log = Fakr.ApiLogger.get_requests(socket.assigns.collection_key, filter)
    {:noreply, assign(socket, activity_client_filter: filter, activity_log: log)}
  end

  def handle_event("toggle_activity_detail", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    entry = Enum.find(socket.assigns.activity_log, &(&1.id == id))
    {:noreply, assign(socket, activity_detail: entry)}
  end

  def handle_event("close_activity_detail", _params, socket) do
    {:noreply, assign(socket, activity_detail: nil)}
  end

  @impl true
  def handle_info({:new_request, entry}, socket) do
    filter = socket.assigns.activity_client_filter

    # Apply client filter
    show? =
      case filter do
        "" -> true
        nil -> true
        f -> entry.client == f
      end

    if show? do
      updated = Enum.take([entry | socket.assigns.activity_log], 50)
      {:noreply, assign(socket, activity_log: updated)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_try_params", params, socket) do
    socket =
      socket
      |> maybe_update(:try_page, params["page"])
      |> maybe_update(:try_limit, params["limit"], 100)
      |> maybe_update(:try_detail_id, params["detail_id"])

    {:noreply, socket}
  end

  def handle_event("try_api", _params, socket) do
    case socket.assigns.try_mode do
      "list" -> do_try_list(socket)
      "detail" -> do_try_detail(socket, socket.assigns.try_detail_id)
    end
  end

  def handle_event("try_detail_quick", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)

    {:noreply, socket |> assign(try_mode: "detail", try_detail_id: id)}
    |> then(fn {:noreply, socket} -> do_try_detail(socket, id) end)
  end

  # --- Private ---

  defp do_try_list(socket) do
    resource = socket.assigns.selected_resource
    page = socket.assigns.try_page
    limit = socket.assigns.try_limit

    query_params = %{"page" => to_string(page), "limit" => to_string(limit)}
    {records, pagination} = Mocks.get_generated_records(resource.id, query_params)
    plural_name = resource.name |> Inflex.pluralize() |> String.downcase()

    record_ids = Enum.map(records, fn r -> r.data["id"] end)

    response = %{
      "data" => %{
        plural_name => Enum.map(records, & &1.data),
        "pagination" => pagination
      }
    }

    json = Jason.encode!(response, pretty: true)

    {:noreply,
     assign(socket,
       try_response: json,
       try_status: 200,
       list_record_ids: record_ids
     )}
  end

  defp do_try_detail(socket, id) do
    resource = socket.assigns.selected_resource
    record = Mocks.get_generated_record(resource.id, id)

    if record do
      singular_name = resource.name |> Inflex.singularize() |> String.downcase()

      response = %{
        "data" => %{
          singular_name => record.data
        }
      }

      json = Jason.encode!(response, pretty: true)

      {:noreply,
       assign(socket,
         try_response: json,
         try_status: 200,
         try_detail_id: id
       )}
    else
      json = Jason.encode!(%{"error" => "Record not found"}, pretty: true)

      {:noreply,
       assign(socket,
         try_response: json,
         try_status: 404,
         try_detail_id: id
       )}
    end
  end

  defp maybe_update(socket, _key, nil), do: socket

  defp maybe_update(socket, key, val, max \\ nil) do
    case parse_int(val, nil) do
      nil -> socket
      n -> assign(socket, [{key, if(max, do: min(n, max), else: n)}])
    end
  end

  defp parse_int(nil, default), do: default

  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} when n > 0 -> n
      _ -> default
    end
  end

  defp parse_int(val, _default) when is_integer(val), do: val

  defp try_full_url(assigns) do
    base = "#{assigns.base_url}/@#{assigns.username}/#{assigns.collection.slug}/api/#{assigns.selected_resource.slug}"

    case assigns.try_mode do
      "list" -> "#{base}?page=#{assigns.try_page}&limit=#{assigns.try_limit}"
      "detail" -> "#{base}/#{assigns.try_detail_id}"
    end
  end

  defp api_base_url(assigns) do
    "#{assigns.base_url}/@#{assigns.username}/#{assigns.collection.slug}/api/#{assigns.selected_resource.slug}"
  end

  defp snippet_curl(assigns) do
    "curl \"#{api_base_url(assigns)}?page=1&limit=10\""
  end

  defp snippet_fetch(assigns) do
    url = api_base_url(assigns)

    """
    const res = await fetch("#{url}?page=1&limit=10");
    const data = await res.json();
    console.log(data);\
    """
  end

  defp snippet_python(assigns) do
    url = api_base_url(assigns)

    """
    import requests

    res = requests.get("#{url}", params={"page": 1, "limit": 10})
    print(res.json())\
    """
  end

  attr :path, :string, required: true
  attr :base_url, :string, required: true
  attr :description, :string, required: true
  attr :hint, :string, default: nil

  defp endpoint_card(assigns) do
    full_url = assigns.base_url <> assigns.path
    assigns = assign(assigns, full_url: full_url)

    ~H"""
    <div class="bg-peppercorn rounded-lg p-4 space-y-1">
      <div class="flex items-center gap-2">
        <span class="text-xs font-bold text-cavendish bg-cavendish/20 px-2 py-0.5 rounded">GET</span>
        <code class="text-sm text-green-400 font-mono flex-1 truncate">{@path}</code>
        <button
          phx-click={JS.dispatch("phx:copy", detail: %{text: @full_url})}
          class="text-gray-500 hover:text-cavendish transition shrink-0"
          title="Copy full URL"
        >
          <.icon name="hero-clipboard" class="w-4 h-4" />
        </button>
      </div>
      <p class="text-[11px] text-gray-500 font-mono truncate">{@full_url}</p>
      <p class="text-xs text-gray-400">{@description}</p>
      <p :if={@hint} class="text-xs text-gray-500">
        {@hint}
      </p>
    </div>
    """
  end

  defp format_time(iso_string) when is_binary(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _} -> Calendar.strftime(dt, "%H:%M:%S")
      _ -> iso_string
    end
  end

  defp format_time(_), do: ""
end
