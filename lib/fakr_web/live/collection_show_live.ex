defmodule FakrWeb.CollectionShowLive do
  use FakrWeb, :live_view

  alias Fakr.Accounts
  alias Fakr.Mocks

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-[1400px] mx-auto">
        <div class="flex gap-0">
          <%!-- ═══ Left Sidebar ═══ --%>
          <nav class="w-48 shrink-0 hidden xl:block">
            <div class="sticky top-20 pr-4 border-r border-smoke">
              <%!-- Resources --%>
              <h4 class="text-[10px] font-semibold text-gray-400 uppercase tracking-widest mb-2">Resources</h4>
              <ul class="space-y-0.5 mb-6">
                <li :for={resource <- @resources}>
                  <button phx-click="select_resource" phx-value-id={resource.id}
                    class={["w-full text-left px-2 py-1.5 rounded text-sm transition",
                      if(@selected_resource && @selected_resource.id == resource.id,
                        do: "bg-cypress/10 text-cypress font-medium",
                        else: "text-gray-500 hover:text-peppercorn hover:bg-smoke/50")]}>
                    {resource.name}
                  </button>
                </li>
              </ul>
              <%!-- Section anchors --%>
              <h4 :if={@selected_resource} class="text-[10px] font-semibold text-gray-400 uppercase tracking-widest mb-2">On this page</h4>
              <ul :if={@selected_resource} class="space-y-0.5">
                <li :for={{id, label} <- [{"endpoints", "Endpoints"}, {"properties", "Properties"}, {"parameters", "Parameters"}, {"tryit", "Try It"}, {"activity", "Activity"}]}>
                  <a href={"##{id}"} class="block px-2 py-1 text-xs text-gray-400 hover:text-cypress transition">{label}</a>
                </li>
              </ul>
            </div>
          </nav>

          <%!-- ═══ Center Content ═══ --%>
          <div class={["flex-1 min-w-0", if(@selected_resource, do: "xl:pr-6", else: "")]}>
            <%!-- Collection header --%>
            <div class="px-6 pt-2 pb-6 border-b border-smoke mb-6">
              <h1 class="text-2xl font-bold text-peppercorn">{@collection.name}</h1>
              <p class="text-sm text-gray-500 mt-1">by @{@username}</p>
              <p :if={@collection.description} class="text-sm text-gray-500 mt-1">{@collection.description}</p>
              <div class="mt-3 flex items-center gap-2">
                <a href={"/@#{@username}/#{@collection.slug}/openapi.json"} target="_blank" class="text-xs text-gray-400 hover:text-cypress transition">OpenAPI Spec</a>
                <span class="text-gray-300">·</span>
                <a href={"https://petstore.swagger.io/?url=#{URI.encode(@base_url <> "/@#{@username}/#{@collection.slug}/openapi.json")}"} target="_blank" class="text-xs text-gray-400 hover:text-cypress transition">Swagger UI</a>
              </div>
            </div>

            <%!-- Mobile Resource Selector --%>
            <div class="xl:hidden px-6 mb-4">
              <select phx-change="select_resource_mobile" class="select select-bordered select-sm w-full">
                <option :for={resource <- @resources} value={resource.id} selected={@selected_resource && @selected_resource.id == resource.id}>{resource.name}</option>
              </select>
            </div>

            <div :if={@selected_resource} class="px-6">
              <%!-- Resource header --%>
              <div class="mb-8">
                <h2 class="text-xl font-bold text-peppercorn">{@selected_resource.name}</h2>
                <p class="text-xs text-gray-400 mt-1">
                  {Inflex.pluralize(@selected_resource.name) |> String.downcase()} · {@selected_resource.total_records} records
                </p>
              </div>

              <%!-- ── Endpoints ── --%>
              <section id="endpoints" class="mb-10">
                <h3 class="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3 border-b border-smoke pb-2">Endpoints</h3>
                <div class="space-y-1">
                  <.endpoint_row_compact method="GET" path={"/@#{@username}/#{@collection.slug}/api/#{@selected_resource.slug}"} description={"List all #{Inflex.pluralize(@selected_resource.name) |> String.downcase()}"} base_url={@base_url} />
                  <.endpoint_row_compact method="GET" path={"/@#{@username}/#{@collection.slug}/api/#{@selected_resource.slug}/:id"} description={"Retrieve a single #{Inflex.singularize(@selected_resource.name) |> String.downcase()}"} base_url={@base_url} />
                </div>
              </section>

              <%!-- ── Properties ── --%>
              <section id="properties" class="mb-10">
                <h3 class="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3 border-b border-smoke pb-2">Properties</h3>
                <div class="divide-y divide-smoke">
                  <%!-- id (auto) --%>
                  <div class="py-3 flex items-start gap-3">
                    <div class="flex-1">
                      <div class="flex items-center gap-2">
                        <code class="text-sm font-semibold text-peppercorn">id</code>
                        <span class="text-[10px] bg-smoke text-gray-500 px-1.5 py-0.5 rounded font-mono">integer</span>
                        <span class="text-[10px] bg-cypress/10 text-cypress px-1.5 py-0.5 rounded">auto</span>
                      </div>
                      <p class="text-xs text-gray-400 mt-0.5">Auto-incremented record identifier.</p>
                    </div>
                  </div>
                  <%!-- Fields --%>
                  <.property_row :for={field <- visible_fields(@selected_resource.fields)} field={field} />
                </div>
              </section>

              <%!-- ── Query Parameters ── --%>
              <section id="parameters" class="mb-10">
                <h3 class="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3 border-b border-smoke pb-2">Query Parameters</h3>
                <div class="divide-y divide-smoke">
                  <div :for={{param, desc} <- query_params_ref()} class="py-2 flex items-start gap-3">
                    <code class="text-xs font-mono text-cypress w-32 shrink-0 pt-0.5">{param}</code>
                    <span class="text-xs text-gray-500">{desc}</span>
                  </div>
                </div>
              </section>

              <%!-- ── Try It ── --%>
              <section id="tryit" class="mb-10">
                <h3 class="text-xs font-semibold text-gray-400 uppercase tracking-widest mb-3 border-b border-smoke pb-2">Try It</h3>

                <div class="flex items-center gap-2 mb-3">
                  <button :for={{mode, label} <- [{"list", "List"}, {"detail", "Detail"}]}
                    phx-click="set_try_mode" phx-value-mode={mode}
                    class={["px-3 py-1 text-xs rounded font-medium transition",
                      if(@try_mode == mode, do: "bg-cypress text-white", else: "bg-smoke text-gray-500 hover:bg-smoke-dark")]}>
                    {label}
                  </button>
                </div>

                <%!-- URL bar --%>
                <div class="bg-peppercorn rounded-lg px-3 py-2 mb-3">
                  <div class="flex items-center gap-2 font-mono text-sm">
                    <span class="text-xs font-bold text-cavendish bg-cavendish/20 px-1.5 py-0.5 rounded">GET</span>
                    <span class="text-green-400 truncate flex-1">
                      /@{@username}/{@collection.slug}/api/{@selected_resource.slug}<%= if @try_mode == "list" do %>?page={@try_page}&limit={@try_limit}<% else %>/{@try_detail_id}<% end %>
                    </span>
                    <button phx-click={JS.dispatch("phx:copy", detail: %{text: try_full_url(assigns)})} class="text-gray-500 hover:text-cavendish transition shrink-0"><.icon name="hero-clipboard" class="w-4 h-4" /></button>
                  </div>
                </div>

                <div class="flex items-end gap-3 mb-3 flex-wrap">
                  <%= if @try_mode == "list" do %>
                    <div>
                      <label class="block text-xs text-gray-400 mb-1">Page</label>
                      <input type="number" value={@try_page} phx-change="update_try_params" name="page" min="1" class="input input-bordered input-sm w-20" />
                    </div>
                    <div>
                      <label class="block text-xs text-gray-400 mb-1">Limit</label>
                      <input type="number" value={@try_limit} phx-change="update_try_params" name="limit" min="1" max="100" class="input input-bordered input-sm w-20" />
                    </div>
                  <% else %>
                    <div>
                      <label class="block text-xs text-gray-400 mb-1">Record ID</label>
                      <input type="number" value={@try_detail_id} phx-change="update_try_params" name="detail_id" min="1" class="input input-bordered input-sm w-24" />
                    </div>
                  <% end %>
                  <button phx-click="try_api" class="px-4 py-1.5 bg-cypress text-white text-sm rounded-lg hover:bg-cypress/90 transition font-medium">
                    Send
                  </button>
                </div>

                <%!-- Response (shown in center on mobile, mirrored to right panel on desktop) --%>
                <div :if={@try_response} class="xl:hidden">
                  <pre class="bg-peppercorn text-green-400 p-4 rounded-lg overflow-x-auto text-xs font-mono whitespace-pre-wrap max-h-96 overflow-y-auto"><code>{@try_response}</code></pre>
                  <div :if={@try_mode == "list" && @list_record_ids != []} class="mt-2">
                    <p class="text-xs text-gray-400 mb-1">Quick detail:</p>
                    <div class="flex flex-wrap gap-1">
                      <button :for={rid <- @list_record_ids} phx-click="try_detail_quick" phx-value-id={rid}
                        class="px-2 py-0.5 text-xs font-mono bg-smoke hover:bg-cypress hover:text-white text-peppercorn rounded transition">/{rid}</button>
                    </div>
                  </div>
                </div>
              </section>

              <%!-- ── Activity ── --%>
              <section id="activity" class="mb-10">
                <div class="flex items-center justify-between mb-3 border-b border-smoke pb-2">
                  <h3 class="text-xs font-semibold text-gray-400 uppercase tracking-widest">Activity</h3>
                  <div class="flex items-center gap-2">
                    <form phx-change="update_activity_filter" class="flex items-center gap-1.5">
                      <input type="text" value={@activity_client_filter} name="client_filter" placeholder="_client=..." phx-debounce="300" class="input input-bordered input-xs w-24 font-mono" />
                    </form>
                    <span class="flex items-center gap-1 text-[10px] text-green-500">
                      <span class="w-1.5 h-1.5 bg-green-500 rounded-full animate-pulse"></span> live
                    </span>
                  </div>
                </div>

                <div :if={@activity_log == []} class="text-center py-8 text-gray-400 text-xs">
                  Requests will appear here in real-time. Add <code class="bg-smoke px-1 rounded">?_client=my-app</code> to filter.
                </div>

                <div :if={@activity_log != []} class="divide-y divide-smoke/50">
                  <div :for={entry <- @activity_log}
                    class="flex items-center gap-3 py-2 hover:bg-smoke/30 transition cursor-pointer rounded -mx-2 px-2"
                    phx-click="toggle_activity_detail" phx-value-id={entry.id}>
                    <span class={["w-8 text-[11px] font-mono font-bold text-center",
                      cond do
                        entry.status < 300 -> "text-green-600"
                        entry.status < 400 -> "text-yellow-600"
                        true -> "text-red-500"
                      end]}>{entry.status}</span>
                    <span class="text-[11px] font-mono text-gray-400 w-10 text-right">{entry.duration_ms}ms</span>
                    <span class="text-[11px] font-mono text-peppercorn flex-1 truncate">{entry.path}</span>
                    <span :if={entry.client} class="text-[9px] bg-blue-100 text-blue-600 px-1 rounded">{entry.client}</span>
                    <span class="text-[10px] text-gray-300">{format_time(entry.timestamp)}</span>
                  </div>
                </div>
              </section>
            </div>

            <div :if={@selected_resource == nil} class="px-6 text-center py-16 text-gray-400">
              Select a resource from the sidebar.
            </div>
          </div>

          <%!-- ═══ Right Code Panel (sticky) ═══ --%>
          <div :if={@selected_resource} class="w-[380px] shrink-0 hidden xl:block">
            <div class="sticky top-20">
              <%!-- Language tabs --%>
              <div class="flex items-center border-b border-gray-700 bg-peppercorn rounded-t-lg">
                <button :for={{lang, label} <- [{"curl", "cURL"}, {"js", "JavaScript"}, {"python", "Python"}]}
                  phx-click="set_code_lang" phx-value-lang={lang}
                  class={["px-3 py-2 text-xs font-medium transition",
                    if(@code_lang == lang,
                      do: "text-cavendish border-b-2 border-cavendish",
                      else: "text-gray-500 hover:text-gray-300")]}>
                  {label}
                </button>
                <div class="flex-1"></div>
                <button phx-click={JS.dispatch("phx:copy", detail: %{text: current_snippet(assigns)})}
                  class="px-3 text-gray-500 hover:text-cavendish transition" title="Copy">
                  <.icon name="hero-clipboard" class="w-3.5 h-3.5" />
                </button>
              </div>

              <%!-- Code content --%>
              <div class="bg-peppercorn rounded-b-lg p-4 max-h-[calc(100vh-12rem)] overflow-y-auto">
                <%!-- Snippet --%>
                <div :if={!@try_response}>
                  <p class="text-[10px] text-gray-500 uppercase tracking-wider mb-2">Example Request</p>
                  <pre class="text-xs text-green-400 font-mono whitespace-pre-wrap">{current_snippet(assigns)}</pre>

                  <p class="text-[10px] text-gray-500 uppercase tracking-wider mt-6 mb-2">Example Response</p>
                  <pre class="text-xs text-green-400 font-mono whitespace-pre-wrap">{@sample_json}</pre>
                </div>

                <%!-- Try It response (replaces example when available) --%>
                <div :if={@try_response}>
                  <div class="flex items-center justify-between mb-2">
                    <p class="text-[10px] text-gray-500 uppercase tracking-wider">Response</p>
                    <span class={["text-xs font-mono", if(@try_status == 200, do: "text-green-400", else: "text-red-400")]}>
                      {if @try_status == 200, do: "200 OK", else: "#{@try_status}"}
                    </span>
                  </div>
                  <pre class="text-xs text-green-400 font-mono whitespace-pre-wrap">{@try_response}</pre>

                  <div :if={@try_mode == "list" && @list_record_ids != []} class="mt-3 border-t border-gray-700 pt-2">
                    <p class="text-[10px] text-gray-500 mb-1">Quick detail:</p>
                    <div class="flex flex-wrap gap-1">
                      <button :for={rid <- @list_record_ids} phx-click="try_detail_quick" phx-value-id={rid}
                        class="px-2 py-0.5 text-[10px] font-mono text-gray-400 hover:text-cavendish transition">/{rid}</button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- ═══ Request Detail Modal ═══ --%>
      <div :if={@activity_detail} class="fixed inset-0 z-50 flex items-center justify-center" phx-window-keydown="close_activity_detail" phx-key="Escape">
        <div class="fixed inset-0 bg-black/50" phx-click="close_activity_detail"></div>
        <div class="relative bg-white rounded-xl shadow-xl w-full max-w-2xl mx-4 z-10 max-h-[85vh] overflow-y-auto">
          <div class="sticky top-0 bg-white border-b border-smoke px-6 py-4 flex items-center justify-between rounded-t-xl">
            <div class="flex items-center gap-3">
              <span class={["px-2 py-1 text-sm font-bold rounded",
                cond do
                  @activity_detail.status < 300 -> "bg-green-100 text-green-700"
                  @activity_detail.status < 400 -> "bg-yellow-100 text-yellow-700"
                  true -> "bg-red-100 text-red-700"
                end]}>{@activity_detail.status}</span>
              <span class="font-mono text-sm text-peppercorn font-semibold">{@activity_detail.method}</span>
              <span class="text-xs text-gray-400">{@activity_detail.duration_ms}ms</span>
            </div>
            <button phx-click="close_activity_detail" class="text-gray-400 hover:text-gray-600"><.icon name="hero-x-mark" class="w-5 h-5" /></button>
          </div>
          <div class="px-6 py-4 space-y-5">
            <div>
              <h4 class="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">URL</h4>
              <code class="text-sm font-mono text-peppercorn break-all">{@activity_detail.path}<%= if @activity_detail.query_string != "" do %>?{@activity_detail.query_string}<% end %></code>
            </div>
            <div class="flex items-center gap-4 text-sm text-gray-500">
              <span>{@activity_detail.timestamp}</span>
              <span :if={@activity_detail.client} class="text-xs bg-blue-100 text-blue-600 px-2 py-0.5 rounded">client: {@activity_detail.client}</span>
            </div>
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

  # ══════════════════════════════════════════════════════════════════════
  # Components
  # ══════════════════════════════════════════════════════════════════════

  attr :method, :string, required: true
  attr :path, :string, required: true
  attr :description, :string, required: true
  attr :base_url, :string, required: true

  defp endpoint_row_compact(assigns) do
    assigns = assign(assigns, full_url: assigns.base_url <> assigns.path)

    ~H"""
    <div class="flex items-center gap-3 py-2 group">
      <span class="text-[10px] font-bold text-white bg-green-600 px-1.5 py-0.5 rounded w-10 text-center">{@method}</span>
      <code class="text-sm font-mono text-peppercorn flex-1 truncate">{@path}</code>
      <span class="text-xs text-gray-400 hidden sm:inline">{@description}</span>
      <button phx-click={JS.dispatch("phx:copy", detail: %{text: @full_url})}
        class="text-gray-300 hover:text-cypress transition opacity-0 group-hover:opacity-100 shrink-0">
        <.icon name="hero-clipboard" class="w-3.5 h-3.5" />
      </button>
    </div>
    """
  end

  attr :field, :map, required: true

  defp property_row(assigns) do
    f = assigns.field
    {_prefix, bare} = split_name(f.name)
    type = infer_display_type(f)
    is_nested = String.contains?(f.name, ".")
    depth = length(String.split(f.name, ".")) - 1

    assigns = assign(assigns, bare: bare, type: type, is_nested: is_nested, depth: depth)

    ~H"""
    <div class="py-3" style={"padding-left: #{@depth * 20}px"}>
      <div class="flex items-center gap-2 flex-wrap">
        <span :if={@depth > 0} class="text-gray-300 text-xs">└</span>
        <code class="text-sm font-semibold text-peppercorn">{@bare}</code>
        <span class="text-[10px] bg-smoke text-gray-500 px-1.5 py-0.5 rounded font-mono">{@type}</span>
        <span :if={@field.options["is_array"] == "true"} class="text-[10px] bg-blue-50 text-blue-500 px-1.5 py-0.5 rounded">array</span>
      </div>
      <p class="text-xs text-gray-400 mt-0.5" style={"padding-left: #{if @depth > 0, do: 16, else: 0}px"}>
        {@field.faker_category}.{@field.faker_function}
        <span :for={{k, v} <- @field.options || %{}} :if={v != "" && v != nil && k not in ["is_array", "array_count", "array_count_mode", "array_min", "array_max"]}
          class="text-gray-300"> · {k}: {v}</span>
      </p>
    </div>
    """
  end

  # ══════════════════════════════════════════════════════════════════════
  # Mount
  # ══════════════════════════════════════════════════════════════════════

  @impl true
  def mount(%{"username" => username, "collection_slug" => slug}, _session, socket) do
    user = Accounts.get_user_by_username!(username)
    collection = Mocks.get_collection_by_slug!(user.id, slug)
    published_resources = Enum.filter(collection.resources, & &1.published)

    if published_resources == [] do
      {:ok, socket |> put_flash(:error, "This collection has no published resources.") |> redirect(to: ~p"/")}
    else
      resources = published_resources
      selected = List.first(resources)
      collection_key = "#{username}/#{slug}"

      if connected?(socket) do
        Phoenix.PubSub.subscribe(Fakr.PubSub, "api_log:#{collection_key}")
      end

      sample = generate_sample_json(selected)

      {:ok,
       socket
       |> assign(
         collection: collection,
         resources: resources,
         selected_resource: selected,
         username: username,
         collection_key: collection_key,
         code_lang: "curl",
         sample_json: sample,
         try_mode: "list",
         try_page: 1,
         try_limit: 10,
         try_detail_id: 1,
         try_response: nil,
         try_status: 200,
         list_record_ids: [],
         base_url: FakrWeb.Endpoint.url(),
         activity_log: Fakr.ApiLogger.get_requests(collection_key),
         activity_client_filter: "",
         activity_detail: nil,
         page_title: "#{collection.name} — @#{username}"
       )}
    end
  end

  # ══════════════════════════════════════════════════════════════════════
  # Events
  # ══════════════════════════════════════════════════════════════════════

  @impl true
  def handle_event("select_resource", %{"id" => id}, socket) do
    resource = Enum.find(socket.assigns.resources, &(&1.id == String.to_integer(id)))
    sample = generate_sample_json(resource)
    {:noreply, assign(socket, selected_resource: resource, sample_json: sample, try_response: nil, try_status: 200, list_record_ids: [], try_mode: "list", try_detail_id: 1)}
  end

  def handle_event("select_resource_mobile", params, socket) do
    id = params["_target"] |> List.first() |> then(fn _ -> params end) |> Map.values() |> List.first()
    case id do
      id when is_binary(id) -> handle_event("select_resource", %{"id" => id}, socket)
      _ -> {:noreply, socket}
    end
  end

  def handle_event("set_code_lang", %{"lang" => lang}, socket) do
    {:noreply, assign(socket, code_lang: lang)}
  end

  def handle_event("set_try_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, try_mode: mode, try_response: nil, try_status: 200, list_record_ids: [])}
  end

  def handle_event("update_try_params", params, socket) do
    socket = socket
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
    show? = filter in ["", nil] || entry.client == filter
    if show? do
      {:noreply, assign(socket, activity_log: Enum.take([entry | socket.assigns.activity_log], 50))}
    else
      {:noreply, socket}
    end
  end

  # ══════════════════════════════════════════════════════════════════════
  # Private
  # ══════════════════════════════════════════════════════════════════════

  defp do_try_list(socket) do
    resource = socket.assigns.selected_resource
    query_params = %{"page" => to_string(socket.assigns.try_page), "limit" => to_string(socket.assigns.try_limit)}
    {records, pagination} = Mocks.get_generated_records(resource.id, query_params)
    plural_name = resource.name |> Inflex.pluralize() |> String.downcase()
    record_ids = Enum.map(records, fn r -> r.data["id"] end)
    response = %{"data" => %{plural_name => Enum.map(records, & &1.data), "pagination" => pagination}}
    {:noreply, assign(socket, try_response: Jason.encode!(response, pretty: true), try_status: 200, list_record_ids: record_ids)}
  end

  defp do_try_detail(socket, id) do
    resource = socket.assigns.selected_resource
    record = Mocks.get_generated_record(resource.id, id)
    if record do
      singular_name = resource.name |> Inflex.singularize() |> String.downcase()
      response = %{"data" => %{singular_name => record.data}}
      {:noreply, assign(socket, try_response: Jason.encode!(response, pretty: true), try_status: 200, try_detail_id: id)}
    else
      {:noreply, assign(socket, try_response: Jason.encode!(%{"error" => "Not found"}, pretty: true), try_status: 404, try_detail_id: id)}
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

  defp current_snippet(assigns) do
    case assigns.code_lang do
      "curl" -> snippet_curl(assigns)
      "js" -> snippet_js(assigns)
      "python" -> snippet_python(assigns)
      _ -> snippet_curl(assigns)
    end
  end

  defp snippet_curl(assigns), do: "curl \"#{api_base_url(assigns)}?page=1&limit=10\""

  defp snippet_js(assigns) do
    url = api_base_url(assigns)
    "const res = await fetch(\"#{url}?page=1&limit=10\");\nconst data = await res.json();\nconsole.log(data);"
  end

  defp snippet_python(assigns) do
    url = api_base_url(assigns)
    "import requests\n\nres = requests.get(\"#{url}\",\n  params={\"page\": 1, \"limit\": 10})\nprint(res.json())"
  end

  defp generate_sample_json(nil), do: "{}"
  defp generate_sample_json(resource) do
    fields = Enum.reject(resource.fields, &String.starts_with?(&1.name, "__group_meta."))
    if fields == [] do
      "{}"
    else
      field_structs = Enum.map(fields, fn f ->
        %Fakr.Mocks.ResourceField{name: f.name, faker_category: f.faker_category, faker_function: f.faker_function, options: f.options || %{}}
      end)
      sample = Mocks.generate_preview(field_structs)
      Jason.encode!(sample, pretty: true)
    end
  end

  defp query_params_ref do
    [
      {"page", "Page number (default: 1)"},
      {"limit", "Items per page (default: 10, max: 100)"},
      {"sort", "Sort by field name"},
      {"order", "asc or desc"},
      {"column=value", "Exact match filter"},
      {"search_column", "Field to search"},
      {"search_term", "Search keyword (case-insensitive)"},
      {"delay", "Response delay in ms (max: 10000)"},
      {"status", "Simulate error (e.g. 500, 401)"},
      {"_client", "App identifier for activity log"}
    ]
  end

  defp visible_fields(fields) do
    Enum.reject(fields, &String.starts_with?(&1.name, "__group_meta."))
  end

  defp split_name(name) do
    case String.split(name, ".", parts: 2) do
      [prefix, bare] -> {prefix, bare}
      [bare] -> {"", bare}
    end
  end

  defp infer_display_type(field) do
    case {field.faker_category, field.faker_function} do
      {"Custom", "integer"} -> "integer"
      {"Custom", "float"} -> "number"
      {"Custom", "price"} -> "string"
      {"Custom", "boolean"} -> "boolean"
      {"Custom", "date_range"} -> "date"
      {"UUID", _} -> "uuid"
      {"Custom", "nanoid"} -> "string"
      {"Custom", "ulid"} -> "string"
      {"Date", _} -> "date"
      {"DateTime", _} -> "datetime"
      {"Commerce", "price"} -> "number"
      {"Address", "latitude"} -> "number"
      {"Address", "longitude"} -> "number"
      _ -> "string"
    end
  end

  defp format_time(iso_string) when is_binary(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, dt, _} -> Calendar.strftime(dt, "%H:%M:%S")
      _ -> iso_string
    end
  end
  defp format_time(_), do: ""
end
