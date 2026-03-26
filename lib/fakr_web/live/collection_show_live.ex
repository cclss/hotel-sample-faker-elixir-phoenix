defmodule FakrWeb.CollectionShowLive do
  use FakrWeb, :live_view

  alias Fakr.Accounts
  alias Fakr.Mocks

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-[1400px] mx-auto pb-12">
        <div class="flex gap-0">
          <%!-- ═══ Left Sidebar ═══ --%>
          <nav class="w-48 shrink-0 hidden xl:block">
            <div class="sticky top-20 pr-4 border-r border-gray-200">
              <h4 class="text-[10px] font-semibold text-gray-400 uppercase tracking-widest mb-2">Resources</h4>
              <ul class="space-y-0.5 mb-6">
                <li :for={resource <- @resources}>
                  <button phx-click="select_resource" phx-value-id={resource.id}
                    class={["w-full text-left px-2.5 py-1.5 rounded text-sm transition",
                      if(@selected_resource && @selected_resource.id == resource.id,
                        do: "bg-indigo/10 text-indigo font-medium",
                        else: "text-navy/60 hover:text-navy hover:bg-gray-100")]}>
                    {resource.name}
                  </button>
                </li>
              </ul>
              <h4 :if={@selected_resource} class="text-[10px] font-semibold text-gray-400 uppercase tracking-widest mb-2">On this page</h4>
              <ul :if={@selected_resource} class="space-y-0.5">
                <li :for={{id, label} <- [{"sec-list", "List endpoint"}, {"sec-detail", "Detail endpoint"}, {"sec-properties", "Properties"}, {"sec-params", "Parameters"}]}>
                  <a href={"##{id}"} class="block px-2.5 py-1 text-xs text-gray-400 hover:text-blue transition">{label}</a>
                </li>
              </ul>
            </div>
          </nav>

          <%!-- ═══ Center Content ═══ --%>
          <div class="flex-1 min-w-0 xl:pr-6">
            <%!-- Collection header --%>
            <div class="px-6 pt-2 pb-6 border-b border-gray-200 mb-8">
              <h1 class="text-2xl font-bold text-navy">{@collection.name}</h1>
              <p class="text-sm text-navy/50 mt-1">by <span class="text-blue">@{@username}</span></p>
              <p :if={@collection.description} class="text-sm text-navy/60 mt-2">{@collection.description}</p>
              <div class="mt-3 flex items-center gap-3">
                <a href={"/@#{@username}/#{@collection.slug}/openapi.json"} target="_blank" class="text-xs text-blue hover:text-indigo transition">OpenAPI Spec</a>
                <span class="text-gray-300">·</span>
                <a href={"https://petstore.swagger.io/?url=#{URI.encode(@base_url <> "/@#{@username}/#{@collection.slug}/openapi.json")}"} target="_blank" class="text-xs text-blue hover:text-indigo transition">Swagger UI</a>
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
                <h2 class="text-xl font-bold text-navy">{@selected_resource.name}</h2>
                <p class="text-xs text-navy/40 mt-1">{@selected_resource.total_records} records</p>
                <div :if={@selected_resource.published && @selected_resource.published_revision != @selected_resource.revision}
                  class="mt-3 flex items-center gap-2 px-3 py-2 bg-amber-50 border border-amber-200 rounded-lg text-xs text-amber-700">
                  <.icon name="hero-exclamation-triangle" class="w-4 h-4 shrink-0" />
                  <span>Schema has been modified since last publish. Example responses reflect current schema, but <strong>Try It</strong> returns published data which may differ.</span>
                </div>
              </div>

              <%!-- ═══ Endpoint: List ═══ --%>
              <section id="sec-list" class="mb-12">
                <div class="flex items-center gap-3 mb-4 pb-3 border-b border-gray-200">
                  <span class="text-[11px] font-bold text-white bg-sky px-2 py-0.5 rounded">GET</span>
                  <code class="text-sm font-mono text-navy font-semibold">/@{@username}/{@collection.slug}/api/{@selected_resource.slug}</code>
                </div>
                <p class="text-sm text-navy/60 mb-6">
                  List all {Inflex.pluralize(@selected_resource.name) |> String.downcase()} with pagination, filtering, and sorting.
                </p>

                <%!-- Properties --%>
                <div id="sec-properties" class="mb-8">
                  <h4 class="text-xs font-semibold text-deep-violet uppercase tracking-widest mb-3">Response Properties</h4>
                  <div class="divide-y divide-gray-100">
                    <div class="py-3">
                      <div class="flex items-center gap-2">
                        <code class="text-sm font-semibold text-navy">id</code>
                        <span class="text-[10px] bg-cyan/10 text-cyan px-1.5 py-0.5 rounded font-mono">integer</span>
                        <span class="text-[10px] bg-mint/20 text-teal px-1.5 py-0.5 rounded">auto</span>
                      </div>
                      <p class="text-xs text-navy/40 mt-0.5">Auto-incremented record identifier.</p>
                    </div>
                    <.property_row :for={field <- visible_fields(@selected_resource.fields)} field={field} />
                  </div>
                </div>

                <%!-- Query Parameters --%>
                <div id="sec-params" class="mb-6">
                  <h4 class="text-xs font-semibold text-deep-violet uppercase tracking-widest mb-3">Query Parameters</h4>
                  <div class="divide-y divide-gray-100">
                    <div :for={{param, desc} <- query_params_ref()} class="py-2 flex items-start gap-3">
                      <code class="text-xs font-mono text-indigo w-32 shrink-0 pt-0.5">{param}</code>
                      <span class="text-xs text-navy/50">{desc}</span>
                    </div>
                  </div>
                </div>
              </section>

              <%!-- ═══ Endpoint: Detail ═══ --%>
              <section id="sec-detail" class="mb-12">
                <div class="flex items-center gap-3 mb-4 pb-3 border-b border-gray-200">
                  <span class="text-[11px] font-bold text-white bg-sky px-2 py-0.5 rounded">GET</span>
                  <code class="text-sm font-mono text-navy font-semibold">/@{@username}/{@collection.slug}/api/{@selected_resource.slug}/:id</code>
                </div>
                <p class="text-sm text-navy/60 mb-4">
                  Retrieve a single {Inflex.singularize(@selected_resource.name) |> String.downcase()} by its ID.
                </p>
                <div class="divide-y divide-gray-100">
                  <div class="py-2 flex items-start gap-3">
                    <code class="text-xs font-mono text-indigo w-32 shrink-0 pt-0.5">id</code>
                    <span class="text-xs text-navy/50">Record ID (integer, 1-based)</span>
                  </div>
                </div>
              </section>
            </div>

            <div :if={@selected_resource == nil} class="px-6 text-center py-16 text-gray-400">
              Select a resource from the sidebar.
            </div>
          </div>

          <%!-- ═══ Right Code Panel (sticky) ═══ --%>
          <div :if={@selected_resource} class="w-[400px] shrink-0 hidden xl:block">
            <div class="sticky top-20 space-y-0">
              <%!-- List / Detail toggle (top-level) --%>
              <div class="flex items-center gap-1 mb-3">
                <button :for={{mode, label} <- [{"list", "List"}, {"detail", "Detail"}]}
                  phx-click="set_try_mode" phx-value-mode={mode}
                  class={["px-3 py-1.5 text-xs rounded-lg font-medium transition",
                    if(@try_mode == mode, do: "bg-indigo text-white", else: "bg-gray-100 text-navy/50 hover:bg-gray-200")]}>
                  {label}
                </button>
              </div>

              <%!-- Request --%>
              <div class="bg-code-bg rounded-t-xl overflow-hidden">
                <div class="flex items-center border-b border-white/10">
                  <button :for={{lang, label} <- [{"tryit", "Try It"}, {"curl", "cURL"}, {"js", "JS"}, {"python", "Py"}]}
                    phx-click="set_code_lang" phx-value-lang={lang}
                    class={["px-3 py-2.5 text-[11px] font-medium transition",
                      if(@code_lang == lang, do: "text-mint-light border-b-2 border-mint-light", else: "text-white/40 hover:text-white/70")]}>
                    {label}
                  </button>
                  <div class="flex-1"></div>
                  <button :if={@code_lang != "tryit"} phx-click={JS.dispatch("phx:copy", detail: %{text: current_snippet(assigns)})}
                    class="px-3 text-white/30 hover:text-mint-light transition"><.icon name="hero-clipboard" class="w-3.5 h-3.5" /></button>
                </div>
                <div class="p-4">
                  <%!-- Try It controls --%>
                  <div :if={@code_lang == "tryit"}>
                    <div class="bg-white/5 rounded-lg px-3 py-2 mb-3 font-mono text-xs text-mint-light truncate">
                      <span class="text-sky font-bold mr-1">GET</span>
                      <span class="text-white/60">
                        /@{@username}/{@collection.slug}/api/{@selected_resource.slug}<%= if @try_mode == "list" do %>?page={@try_page}&limit={@try_limit}<% else %>/{@try_detail_id}<% end %>
                      </span>
                    </div>
                    <div class="flex items-end gap-2">
                      <%= if @try_mode == "list" do %>
                        <div>
                          <label class="block text-[10px] text-white/30 mb-0.5">Page</label>
                          <input type="number" value={@try_page} phx-change="update_try_params" name="page" min="1" class="bg-white/10 text-white text-xs rounded px-2 py-1 w-14 border-0 focus:ring-1 focus:ring-indigo" />
                        </div>
                        <div>
                          <label class="block text-[10px] text-white/30 mb-0.5">Limit</label>
                          <input type="number" value={@try_limit} phx-change="update_try_params" name="limit" min="1" max="100" class="bg-white/10 text-white text-xs rounded px-2 py-1 w-14 border-0 focus:ring-1 focus:ring-indigo" />
                        </div>
                      <% else %>
                        <div>
                          <label class="block text-[10px] text-white/30 mb-0.5">ID</label>
                          <input type="number" value={@try_detail_id} phx-change="update_try_params" name="detail_id" min="1" class="bg-white/10 text-white text-xs rounded px-2 py-1 w-16 border-0 focus:ring-1 focus:ring-indigo" />
                        </div>
                      <% end %>
                      <button phx-click="try_api" class="px-4 py-1 bg-indigo text-white text-xs rounded hover:bg-violet transition font-medium">Send</button>
                    </div>
                  </div>
                  <%!-- Code snippets --%>
                  <div :if={@code_lang != "tryit"}>
                    <p class="text-[10px] text-white/30 uppercase tracking-wider mb-2">Request</p>
                    <pre class="text-xs text-mint-light font-mono whitespace-pre-wrap">{current_snippet(assigns)}</pre>
                  </div>
                </div>
              </div>

              <%!-- Response --%>
              <div class="bg-code-bg rounded-b-xl overflow-hidden border-t border-white/5">
                <div class="flex items-center justify-between px-4 py-2 border-b border-white/10">
                  <p class="text-[10px] text-white/30 uppercase tracking-wider">Response</p>
                  <span :if={@try_response} class={["text-xs font-mono", if(@try_status == 200, do: "text-teal", else: "text-red-400")]}>
                    {if @try_status == 200, do: "200 OK", else: "#{@try_status}"}
                  </span>
                  <span :if={!@try_response} class="text-[10px] text-white/20">
                    example
                    <span :if={@selected_resource.published && @selected_resource.published_revision != @selected_resource.revision} class="text-amber-400 ml-1" title="Schema changed since publish">*</span>
                  </span>
                </div>
                <div class="p-4 max-h-[40vh] overflow-y-auto">
                  <pre class="text-xs text-mint-light font-mono whitespace-pre-wrap">{if @try_response, do: @try_response, else: if(@try_mode == "list", do: @sample_list_json, else: @sample_detail_json)}</pre>
                  <div :if={@try_response && @try_mode == "list" && @list_record_ids != []} class="mt-3 border-t border-white/10 pt-2">
                    <p class="text-[10px] text-white/30 mb-1">Quick detail:</p>
                    <div class="flex flex-wrap gap-1">
                      <button :for={rid <- @list_record_ids} phx-click="try_detail_quick" phx-value-id={rid}
                        class="px-2 py-0.5 text-[10px] font-mono text-white/40 hover:text-mint-light transition">/{rid}</button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- ═══ Activity Dock (bottom panel) ═══ --%>
      <div class={[
        "fixed bottom-0 left-0 right-0 z-40 bg-code-bg text-white transition-all duration-300 shadow-2xl",
        if(@activity_open, do: "h-[40vh]", else: "h-10")
      ]}>
        <%!-- Dock header --%>
        <button phx-click="toggle_activity" class="w-full h-10 px-4 flex items-center justify-between border-t border-white/10 hover:bg-white/5 transition">
          <div class="flex items-center gap-2">
            <.icon name={if @activity_open, do: "hero-chevron-down", else: "hero-chevron-up"} class="w-3.5 h-3.5 text-white/40" />
            <span class="text-xs font-medium text-white/60">Activity</span>
            <span :if={@activity_log != []} class="flex items-center gap-1 text-[10px] text-teal">
              <span class="w-1.5 h-1.5 bg-teal rounded-full animate-pulse"></span>
              {length(@activity_log)}
            </span>
          </div>
          <form :if={@activity_open} phx-change="update_activity_filter" class="flex items-center gap-1.5" onclick="event.stopPropagation()">
            <input type="text" value={@activity_client_filter} name="client_filter" placeholder="_client filter" phx-debounce="300" class="bg-white/10 text-white text-[11px] rounded px-2 py-0.5 w-28 border-0 focus:ring-1 focus:ring-indigo" />
          </form>
        </button>
        <%!-- Dock content --%>
        <div :if={@activity_open} class="h-[calc(40vh-2.5rem)] overflow-y-auto px-4">
          <div :if={@activity_log == []} class="text-center py-8 text-white/30 text-xs">
            Requests will appear here. Add <code class="bg-white/10 px-1 rounded">?_client=my-app</code> to filter.
          </div>
          <div :if={@activity_log != []} class="divide-y divide-white/5">
            <div :for={entry <- @activity_log}
              class="flex items-center gap-3 py-1.5 hover:bg-white/5 transition cursor-pointer rounded -mx-2 px-2"
              phx-click="toggle_activity_detail" phx-value-id={entry.id}>
              <span class={["w-8 text-[11px] font-mono font-bold text-center",
                cond do
                  entry.status < 300 -> "text-teal"
                  entry.status < 400 -> "text-yellow-400"
                  true -> "text-red-400"
                end]}>{entry.status}</span>
              <span class="text-[11px] font-mono text-white/30 w-10 text-right">{entry.duration_ms}ms</span>
              <span class="text-[11px] font-mono text-white/60 flex-1 truncate">{entry.path}<span :if={entry.query_string != ""} class="text-white/20">?{entry.query_string}</span></span>
              <span :if={entry.client} class="text-[9px] bg-indigo/30 text-sky px-1.5 rounded">{entry.client}</span>
              <span class="text-[10px] text-white/20">{format_time(entry.timestamp)}</span>
            </div>
          </div>
        </div>
      </div>

      <%!-- ═══ Request Detail Modal ═══ --%>
      <div :if={@activity_detail} class="fixed inset-0 z-50 flex items-center justify-center" phx-window-keydown="close_activity_detail" phx-key="Escape">
        <div class="fixed inset-0 bg-black/50" phx-click="close_activity_detail"></div>
        <div class="relative bg-white rounded-xl shadow-xl w-full max-w-2xl mx-4 z-10 max-h-[85vh] overflow-y-auto">
          <div class="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between rounded-t-xl">
            <div class="flex items-center gap-3">
              <span class={["px-2 py-1 text-sm font-bold rounded",
                cond do
                  @activity_detail.status < 300 -> "bg-teal/20 text-teal"
                  @activity_detail.status < 400 -> "bg-yellow-100 text-yellow-700"
                  true -> "bg-red-100 text-red-700"
                end]}>{@activity_detail.status}</span>
              <span class="font-mono text-sm text-navy font-semibold">{@activity_detail.method}</span>
              <span class="text-xs text-navy/40">{@activity_detail.duration_ms}ms</span>
            </div>
            <button phx-click="close_activity_detail" class="text-gray-400 hover:text-gray-600"><.icon name="hero-x-mark" class="w-5 h-5" /></button>
          </div>
          <div class="px-6 py-4 space-y-5">
            <div>
              <h4 class="text-xs font-semibold text-deep-violet uppercase tracking-wider mb-1">URL</h4>
              <code class="text-sm font-mono text-navy break-all">{@activity_detail.path}<%= if @activity_detail.query_string != "" do %>?{@activity_detail.query_string}<% end %></code>
            </div>
            <div class="flex items-center gap-4 text-sm text-navy/50">
              <span>{@activity_detail.timestamp}</span>
              <span :if={@activity_detail.client} class="text-xs bg-indigo/10 text-indigo px-2 py-0.5 rounded">client: {@activity_detail.client}</span>
            </div>
            <div>
              <h4 class="text-xs font-semibold text-deep-violet uppercase tracking-wider mb-2">Request Headers</h4>
              <div class="bg-page-bg rounded-lg p-3 overflow-x-auto">
                <table class="text-xs font-mono w-full">
                  <tbody>
                    <tr :for={{name, value} <- @activity_detail.request_headers || []} class="border-b border-gray-200/50 last:border-0">
                      <td class="py-1 pr-3 text-navy/40 whitespace-nowrap align-top">{name}</td>
                      <td class="py-1 text-navy break-all">{value}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
            <div>
              <h4 class="text-xs font-semibold text-deep-violet uppercase tracking-wider mb-2">Response Headers</h4>
              <div class="bg-page-bg rounded-lg p-3 overflow-x-auto">
                <table class="text-xs font-mono w-full">
                  <tbody>
                    <tr :for={{name, value} <- @activity_detail.response_headers || []} class="border-b border-gray-200/50 last:border-0">
                      <td class="py-1 pr-3 text-navy/40 whitespace-nowrap align-top">{name}</td>
                      <td class="py-1 text-navy break-all">{value}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
            <div>
              <h4 class="text-xs font-semibold text-deep-violet uppercase tracking-wider mb-2">Response Body</h4>
              <pre class="bg-code-bg text-mint-light p-4 rounded-lg overflow-x-auto text-xs font-mono whitespace-pre-wrap max-h-72 overflow-y-auto"><code>{@activity_detail.response_body || "(empty)"}</code></pre>
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

  attr :field, :map, required: true

  defp property_row(assigns) do
    f = assigns.field
    {_prefix, bare} = split_name(f.name)
    type = infer_display_type(f)
    depth = length(String.split(f.name, ".")) - 1
    assigns = assign(assigns, bare: bare, type: type, depth: depth)

    ~H"""
    <div class="py-3" style={"padding-left: #{@depth * 20}px"}>
      <div class="flex items-center gap-2 flex-wrap">
        <span :if={@depth > 0} class="text-gray-300 text-xs">└</span>
        <code class="text-sm font-semibold text-navy">{@bare}</code>
        <span class="text-[10px] bg-cyan/10 text-cyan px-1.5 py-0.5 rounded font-mono">{@type}</span>
        <span :if={@field.options["is_array"] == "true"} class="text-[10px] bg-deep-violet/10 text-deep-violet px-1.5 py-0.5 rounded">array</span>
      </div>
      <p class="text-xs text-navy/40 mt-0.5" style={"padding-left: #{if @depth > 0, do: 16, else: 0}px"}>
        <span class="text-navy/30">{@field.faker_category}.{@field.faker_function}</span>
        <span :for={{k, v} <- @field.options || %{}} :if={v != "" && v != nil && k not in ["is_array", "array_count", "array_count_mode", "array_min", "array_max"]}
          class="text-navy/20"> · {k}: {v}</span>
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
      {:ok, socket |> put_flash(:error, "No published resources.") |> redirect(to: ~p"/")}
    else
      resources = published_resources
      selected = List.first(resources)
      collection_key = "#{username}/#{slug}"

      if connected?(socket), do: Phoenix.PubSub.subscribe(Fakr.PubSub, "api_log:#{collection_key}")

      {:ok,
       socket
       |> assign(
         collection: collection, resources: resources, selected_resource: selected,
         username: username, collection_key: collection_key,
         code_lang: "tryit",
         sample_list_json: generate_sample_list_json(selected),
         sample_detail_json: generate_sample_detail_json(selected),
         try_mode: "list", try_page: 1, try_limit: 10, try_detail_id: 1,
         try_response: nil, try_status: 200, list_record_ids: [],
         base_url: FakrWeb.Endpoint.url(),
         activity_log: Fakr.ApiLogger.get_requests(collection_key),
         activity_client_filter: "", activity_detail: nil, activity_open: false,
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
    {:noreply, assign(socket, selected_resource: resource, sample_list_json: generate_sample_list_json(resource), sample_detail_json: generate_sample_detail_json(resource), try_response: nil, try_status: 200, list_record_ids: [], try_mode: "list", try_detail_id: 1)}
  end

  def handle_event("select_resource_mobile", params, socket) do
    id = params["_target"] |> List.first() |> then(fn _ -> params end) |> Map.values() |> List.first()
    case id do
      id when is_binary(id) -> handle_event("select_resource", %{"id" => id}, socket)
      _ -> {:noreply, socket}
    end
  end

  def handle_event("set_code_lang", %{"lang" => lang}, socket), do: {:noreply, assign(socket, code_lang: lang)}
  def handle_event("set_try_mode", %{"mode" => mode}, socket), do: {:noreply, assign(socket, try_mode: mode, try_response: nil, try_status: 200, list_record_ids: [])}

  def handle_event("update_try_params", params, socket) do
    {:noreply, socket |> maybe_update(:try_page, params["page"]) |> maybe_update(:try_limit, params["limit"], 100) |> maybe_update(:try_detail_id, params["detail_id"])}
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
    |> then(fn {:noreply, s} -> do_try_detail(s, id) end)
  end

  def handle_event("toggle_activity", _params, socket), do: {:noreply, assign(socket, activity_open: !socket.assigns.activity_open)}

  def handle_event("update_activity_filter", %{"client_filter" => filter}, socket) do
    {:noreply, assign(socket, activity_client_filter: filter, activity_log: Fakr.ApiLogger.get_requests(socket.assigns.collection_key, filter))}
  end

  def handle_event("toggle_activity_detail", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    {:noreply, assign(socket, activity_detail: Enum.find(socket.assigns.activity_log, &(&1.id == id)))}
  end

  def handle_event("close_activity_detail", _params, socket), do: {:noreply, assign(socket, activity_detail: nil)}

  @impl true
  def handle_info({:new_request, entry}, socket) do
    filter = socket.assigns.activity_client_filter
    if filter in ["", nil] || entry.client == filter do
      {:noreply, assign(socket, activity_log: Enum.take([entry | socket.assigns.activity_log], 50))}
    else
      {:noreply, socket}
    end
  end

  # ══════════════════════════════════════════════════════════════════════
  # Private
  # ══════════════════════════════════════════════════════════════════════

  defp do_try_list(socket) do
    r = socket.assigns.selected_resource
    {records, pagination} = Mocks.get_generated_records(r.id, %{"page" => to_string(socket.assigns.try_page), "limit" => to_string(socket.assigns.try_limit)})
    plural = r.name |> Inflex.pluralize() |> String.downcase()
    ids = Enum.map(records, & &1.data["id"])
    json = Jason.encode!(%{"data" => %{plural => Enum.map(records, & &1.data), "pagination" => pagination}}, pretty: true)
    {:noreply, assign(socket, try_response: json, try_status: 200, list_record_ids: ids)}
  end

  defp do_try_detail(socket, id) do
    r = socket.assigns.selected_resource
    case Mocks.get_generated_record(r.id, id) do
      nil -> {:noreply, assign(socket, try_response: Jason.encode!(%{"error" => "Not found"}, pretty: true), try_status: 404, try_detail_id: id)}
      rec ->
        singular = r.name |> Inflex.singularize() |> String.downcase()
        {:noreply, assign(socket, try_response: Jason.encode!(%{"data" => %{singular => rec.data}}, pretty: true), try_status: 200, try_detail_id: id)}
    end
  end

  defp maybe_update(socket, _key, nil), do: socket
  defp maybe_update(socket, key, val, max \\ nil) do
    case parse_int(val, nil) do
      nil -> socket
      n -> assign(socket, [{key, if(max, do: min(n, max), else: n)}])
    end
  end

  defp parse_int(nil, d), do: d
  defp parse_int(v, d) when is_binary(v), do: (case Integer.parse(v) do; {n, _} when n > 0 -> n; _ -> d; end)
  defp parse_int(v, _) when is_integer(v), do: v

  defp current_snippet(assigns) do
    url = "#{assigns.base_url}/@#{assigns.username}/#{assigns.collection.slug}/api/#{assigns.selected_resource.slug}"
    case assigns.code_lang do
      "curl" -> "curl \"#{url}?page=1&limit=10\""
      "js" -> "const res = await fetch(\"#{url}?page=1&limit=10\");\nconst data = await res.json();\nconsole.log(data);"
      "python" -> "import requests\n\nres = requests.get(\"#{url}\",\n  params={\"page\": 1, \"limit\": 10})\nprint(res.json())"
      _ -> ""
    end
  end

  defp generate_sample_record(nil), do: %{}
  defp generate_sample_record(resource) do
    fields = Enum.reject(resource.fields, &String.starts_with?(&1.name, "__group_meta."))
    if fields == [] do
      %{}
    else
      structs = Enum.map(fields, &%Fakr.Mocks.ResourceField{name: &1.name, faker_category: &1.faker_category, faker_function: &1.faker_function, options: &1.options || %{}})
      Mocks.generate_preview(structs)
    end
  end

  defp generate_sample_list_json(nil), do: "{}"
  defp generate_sample_list_json(resource) do
    plural = resource.name |> Inflex.pluralize() |> String.downcase()
    record = generate_sample_record(resource)
    response = %{
      "data" => %{
        plural => [record],
        "pagination" => %{"page" => 1, "limit" => 10, "total" => resource.total_records, "current_page" => 1, "has_next" => true, "has_prev" => false, "last_page_no" => max(ceil(resource.total_records / 10), 1)}
      }
    }
    Jason.encode!(response, pretty: true)
  end

  defp generate_sample_detail_json(nil), do: "{}"
  defp generate_sample_detail_json(resource) do
    singular = resource.name |> Inflex.singularize() |> String.downcase()
    record = generate_sample_record(resource)
    response = %{"data" => %{singular => record}}
    Jason.encode!(response, pretty: true)
  end

  defp query_params_ref, do: [
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

  defp visible_fields(fields), do: Enum.reject(fields, &String.starts_with?(&1.name, "__group_meta."))

  defp split_name(name) do
    case String.split(name, ".", parts: 2) do
      [p, b] -> {p, b}
      [b] -> {"", b}
    end
  end

  defp infer_display_type(f) do
    case {f.faker_category, f.faker_function} do
      {"Custom", "integer"} -> "integer"
      {"Custom", "float"} -> "number"
      {"Custom", "price"} -> "string"
      {"Custom", "boolean"} -> "boolean"
      {"Custom", "date_range"} -> "date"
      {"UUID", _} -> "uuid"
      {"Date", _} -> "date"
      {"DateTime", _} -> "datetime"
      {"Commerce", "price"} -> "number"
      {"Address", "latitude"} -> "number"
      {"Address", "longitude"} -> "number"
      _ -> "string"
    end
  end

  defp format_time(iso) when is_binary(iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} -> Calendar.strftime(dt, "%H:%M:%S")
      _ -> iso
    end
  end
  defp format_time(_), do: ""
end
