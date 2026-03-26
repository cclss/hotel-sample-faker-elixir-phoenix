defmodule FakrWeb.ResourceLive.Show do
  use FakrWeb, :live_view

  alias Fakr.Mocks
  alias Fakr.Mocks.{ResourceField, FakerRegistry}

  @impl true
  def render(assigns) do
    assigns = assign(assigns, field_tree: build_field_tree(assigns.fields))

    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-6xl mx-auto">
        <.link navigate={~p"/collections/#{@collection_id}"} class="text-sm text-cypress hover:underline mb-4 inline-block">
          &larr; Back to Collection
        </.link>

        <div class="flex items-center justify-between mb-6">
          <div>
            <h1 class="text-2xl font-bold text-peppercorn">{@resource.name}</h1>
            <p class="text-sm text-gray-400 mt-1">
              {@resource.total_records} records · Rev. {@resource.revision}
              <span :if={@resource.revised_at} class="text-gray-300">({Calendar.strftime(@resource.revised_at, "%Y-%m-%d %H:%M")})</span>
            </p>
          </div>
          <button phx-click="open_edit_resource" class="px-3 py-2 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition">
            Edit Resource
          </button>
        </div>

        <%!-- Stale revision warning --%>
        <div :if={@resource.published && @resource.published_revision != @resource.revision} class="mb-6 flex items-center gap-3 p-4 bg-cavendish/20 border border-cavendish rounded-lg">
          <.icon name="hero-exclamation-triangle" class="w-5 h-5 text-peppercorn shrink-0" />
          <div class="flex-1">
            <p class="text-sm font-medium text-peppercorn">Field definitions changed since last publish</p>
            <p class="text-xs text-gray-500">Published: Rev. {if @resource.published_revision, do: @resource.published_revision, else: "—"} · Current: Rev. {@resource.revision}</p>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <button phx-click="revert_to_published" class="px-3 py-1.5 text-xs border border-gray-300 text-gray-600 rounded-lg hover:bg-gray-50 transition font-medium" data-confirm={"Revert to Rev. #{@resource.published_revision}?"}>
              Revert to Rev. {@resource.published_revision}
            </button>
            <.link navigate={~p"/collections/#{@collection_id}"} class="px-3 py-1.5 text-xs bg-cavendish text-peppercorn rounded-lg hover:bg-cavendish/80 transition font-medium">
              Go to Regenerate
            </.link>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <%!-- Left: Field Definitions (Tree) --%>
          <div>
            <div class="bg-white rounded-xl border border-smoke p-6">
              <div class="flex items-center justify-between mb-4">
                <h2 class="text-lg font-semibold text-peppercorn">Field Definitions</h2>
              </div>

              <%!-- Auto id --%>
              <div class="flex items-center p-3 bg-cypress/5 border border-cypress/20 rounded-lg mb-3">
                <span class="font-medium text-peppercorn">id</span>
                <span class="text-sm text-gray-400 ml-2">Auto-generated integer</span>
                <span class="ml-auto text-xs text-cypress bg-cypress/10 px-2 py-0.5 rounded-full">auto</span>
              </div>

              <div :if={@fields == []} class="text-center py-6 text-gray-400">
                <p>No fields yet.</p>
              </div>

              <%!-- Tree render (drag & drop) --%>
              <div id="field-list" phx-hook="Sortable" class="space-y-1">
                <%= for node <- @field_tree do %>
                  <%= case node do %>
                    <% {:field, idx, field} -> %>
                      <div data-node-id={"field:#{field.name}"}>
                        <.field_row field={field} idx={idx} />
                      </div>
                    <% {:group, group_name, children, group_meta} -> %>
                      <div class="mt-2" data-node-id={"group:#{group_name}"}>
                        <%!-- Group header --%>
                        <div class="flex items-center gap-2 px-3 py-2 bg-purple-50 border border-purple-100 rounded-t-lg">
                          <div class="drag-handle cursor-grab active:cursor-grabbing text-purple-300 hover:text-purple-500 transition">
                            <.icon name="hero-bars-3" class="w-4 h-4" />
                          </div>
                          <.icon name="hero-folder" class="w-4 h-4 text-purple-400" />
                          <span class="text-sm font-semibold text-purple-700">{group_name}</span>
                          <%!-- Array badge --%>
                          <span :if={group_meta.is_array} class="text-[10px] bg-blue-100 text-blue-600 px-1.5 py-0.5 rounded font-medium">
                            array
                            <span :if={group_meta.count_mode == "fixed"}>({group_meta.count})</span>
                            <span :if={group_meta.count_mode == "range"}>({group_meta.min}-{group_meta.max})</span>
                          </span>
                          <span :if={!group_meta.is_array} class="text-[10px] bg-purple-100 text-purple-600 px-1.5 py-0.5 rounded font-medium">object</span>
                          <div class="flex-1"></div>
                          <button phx-click="edit_group" phx-value-group={group_name} class="text-xs text-purple-500 hover:text-purple-700 transition" title="Edit group settings">
                            <.icon name="hero-cog-6-tooth" class="w-3.5 h-3.5" />
                          </button>
                          <button phx-click="open_field_modal" phx-value-mode="add" phx-value-prefix={group_name} class="text-xs text-purple-500 hover:text-purple-700 transition" title="Add field">
                            <.icon name="hero-plus" class="w-3.5 h-3.5" />
                          </button>
                          <button phx-click="delete_group" phx-value-group={group_name} class="text-xs text-red-400 hover:text-red-600 transition" data-confirm={"Delete all fields in \"#{group_name}\"?"} title="Delete group">
                            <.icon name="hero-trash" class="w-3.5 h-3.5" />
                          </button>
                        </div>
                        <%!-- Group children --%>
                        <div class="border-l-2 border-purple-100 ml-2 pl-3 space-y-1 py-1">
                          <%= for {:field, idx, field} <- children do %>
                            <.field_row field={field} idx={idx} />
                          <% end %>
                        </div>
                      </div>
                  <% end %>
                <% end %>
              </div>

              <%!-- Action buttons --%>
              <div class="mt-4 flex items-center gap-2">
                <button phx-click="open_field_modal" phx-value-mode="add" phx-value-prefix="" class="px-3 py-1.5 text-xs bg-cypress text-white rounded-lg hover:bg-cypress/90 transition font-medium">
                  <.icon name="hero-plus" class="w-3 h-3 mr-1" /> Add Field
                </button>
                <button phx-click="open_group_modal" class="px-3 py-1.5 text-xs border border-purple-300 text-purple-600 rounded-lg hover:bg-purple-50 transition font-medium">
                  <.icon name="hero-folder-plus" class="w-3 h-3 mr-1" /> Add Group
                </button>
              </div>
            </div>
          </div>

          <%!-- Right: Test Panel --%>
          <div>
            <div class="bg-white rounded-xl border border-smoke p-6">
              <h2 class="text-lg font-semibold text-peppercorn mb-4">Test Panel</h2>
              <div :if={@fields != []} class="space-y-4">
                <div class="space-y-2">
                  <h3 class="text-sm font-medium text-gray-600">API Endpoints</h3>
                  <.endpoint_row path={"/@#{@username}/#{@collection_slug}/api/#{@resource.slug}"} base_url={@base_url} />
                  <.endpoint_row path={"/@#{@username}/#{@collection_slug}/api/#{@resource.slug}/:id"} base_url={@base_url} />
                </div>
                <button phx-click="generate_preview" class="w-full px-4 py-2 bg-cavendish text-peppercorn rounded-lg hover:bg-cavendish/80 transition font-medium text-sm">
                  Generate Preview
                </button>
              </div>
              <div :if={@fields == []} class="text-center py-8 text-gray-400">
                <p>Add fields to preview generated data.</p>
              </div>
              <div :if={@preview_json} class="mt-4">
                <h3 class="text-sm font-medium text-gray-600 mb-2">Preview Response</h3>
                <pre class="bg-peppercorn text-green-400 p-4 rounded-lg overflow-x-auto text-sm font-mono whitespace-pre-wrap max-h-96 overflow-y-auto"><code>{@preview_json}</code></pre>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- ═══ Field Modal (Add/Edit) ═══ --%>
      <.field_modal
        :if={@field_modal}
        mode={@field_modal_mode}
        prefix={@fm_prefix}
        fm_name={@fm_name}
        fm_category={@fm_category}
        fm_function={@fm_function}
        fm_functions={@fm_functions}
        fm_options_schema={@fm_options_schema}
        fm_options={@fm_options}
        categories={@categories}
      />

      <%!-- ═══ Group Name Modal ═══ --%>
      <div :if={@group_modal} class="fixed inset-0 z-50 flex items-center justify-center" phx-window-keydown="close_group_modal" phx-key="Escape">
        <div class="fixed inset-0 bg-black/50" phx-click="close_group_modal"></div>
        <div class="relative bg-white rounded-xl shadow-xl p-6 w-full max-w-sm mx-4 z-10">
          <h2 class="text-lg font-semibold text-peppercorn mb-4">New Group</h2>
          <form phx-submit="create_group">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Group Name</label>
              <input type="text" name="group_name" value="" placeholder="e.g. address, metadata, author" class="input input-bordered w-full" required autofocus />
              <p class="text-xs text-gray-400 mt-1">Fields inside this group will be nested as a JSON object.</p>
            </div>
            <div class="mt-4 flex items-center gap-3">
              <button type="submit" class="btn btn-primary">Create & Add Field</button>
              <button type="button" phx-click="close_group_modal" class="text-sm text-gray-500 hover:underline">Cancel</button>
            </div>
          </form>
        </div>
      </div>

      <%!-- ═══ Group Settings Modal ═══ --%>
      <div :if={@group_edit_modal} class="fixed inset-0 z-50 flex items-center justify-center" phx-window-keydown="close_group_edit" phx-key="Escape">
        <div class="fixed inset-0 bg-black/50" phx-click="close_group_edit"></div>
        <div class="relative bg-white rounded-xl shadow-xl p-6 w-full max-w-sm mx-4 z-10">
          <h2 class="text-lg font-semibold text-peppercorn mb-1">Group: {@ge_group_name}</h2>
          <p class="text-xs text-gray-400 mb-4">Configure how this group appears in the JSON output.</p>
          <form phx-submit="save_group_settings" phx-change="group_edit_change">
            <input type="hidden" name="group_name" value={@ge_group_name} />
            <div class="space-y-3">
              <div class="flex items-center gap-3">
                <label class="flex items-center gap-2 cursor-pointer">
                  <input type="radio" name="group_type" value="object" checked={!@ge_is_array} class="radio radio-sm" />
                  <span class="text-sm text-gray-700">Single object</span>
                </label>
                <label class="flex items-center gap-2 cursor-pointer">
                  <input type="radio" name="group_type" value="array" checked={@ge_is_array} class="radio radio-sm" />
                  <span class="text-sm text-gray-700">Array of objects</span>
                </label>
              </div>
              <div :if={@ge_is_array} class="p-3 bg-blue-50/50 rounded-lg space-y-2">
                <div class="flex items-center gap-3 flex-wrap">
                  <label class="flex items-center gap-1.5">
                    <input type="radio" name="count_mode" value="fixed" checked={(@ge_count_mode || "fixed") == "fixed"} class="radio radio-sm" />
                    <span class="text-sm text-gray-600">Fixed</span>
                    <input type="number" name="count" value={@ge_count} min="1" max="50" class="input input-bordered input-sm w-16" />
                  </label>
                  <label class="flex items-center gap-1.5">
                    <input type="radio" name="count_mode" value="range" checked={@ge_count_mode == "range"} class="radio radio-sm" />
                    <span class="text-sm text-gray-600">Range</span>
                    <input type="number" name="range_min" value={@ge_range_min} min="0" max="50" class="input input-bordered input-sm w-14" />
                    <span class="text-gray-400">-</span>
                    <input type="number" name="range_max" value={@ge_range_max} min="1" max="50" class="input input-bordered input-sm w-14" />
                  </label>
                </div>
              </div>

              <div class="bg-peppercorn rounded-lg p-3 text-xs font-mono text-green-400">
                <%= if @ge_is_array do %>
                  {"\"#{@ge_group_name}\": [{...}, {...}]"}
                <% else %>
                  {"\"#{@ge_group_name}\": {...}"}
                <% end %>
              </div>
            </div>
            <div class="mt-4 flex items-center gap-3">
              <button type="submit" class="btn btn-primary btn-sm">Save</button>
              <button type="button" phx-click="close_group_edit" class="text-sm text-gray-500 hover:underline">Cancel</button>
            </div>
          </form>
        </div>
      </div>

      <%!-- ═══ Edit Resource Modal ═══ --%>
      <div :if={@show_edit_resource} class="fixed inset-0 z-50 flex items-center justify-center" phx-window-keydown="close_edit_resource" phx-key="Escape">
        <div class="fixed inset-0 bg-black/50" phx-click="close_edit_resource"></div>
        <div class="relative bg-white rounded-xl shadow-xl p-6 w-full max-w-md mx-4 z-10">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold text-peppercorn">Edit Resource</h2>
            <button phx-click="close_edit_resource" class="text-gray-400 hover:text-gray-600"><.icon name="hero-x-mark" class="w-5 h-5" /></button>
          </div>
          <.form for={@resource_form} id="edit-resource-form" phx-submit="update_resource">
            <div class="space-y-4">
              <.input field={@resource_form[:name]} type="text" label="Resource Name" required />
              <.input field={@resource_form[:total_records]} type="number" label="Total Records" min="1" max="1000" />
            </div>
            <div class="mt-6 flex items-center gap-3">
              <.button type="submit" class="btn btn-primary">Save</.button>
              <button type="button" phx-click="close_edit_resource" class="text-sm text-gray-500 hover:underline">Cancel</button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # ══════════════════════════════════════════════════════════════════════
  # Components
  # ══════════════════════════════════════════════════════════════════════

  attr :field, :map, required: true
  attr :idx, :integer, required: true

  defp field_row(assigns) do
    bare = display_name(assigns.field.name)
    assigns = assign(assigns, bare_name: bare)

    ~H"""
    <div class="flex items-center gap-2 p-2.5 bg-smoke/40 rounded-lg group hover:bg-smoke/70 transition">
      <div class="drag-handle cursor-grab active:cursor-grabbing text-gray-300 hover:text-gray-500 transition shrink-0">
        <.icon name="hero-bars-3" class="w-3.5 h-3.5" />
      </div>
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-1.5">
          <span class="font-medium text-peppercorn text-sm">{@bare_name}</span>
          <span :if={@field.options["is_array"] == "true"} class="text-[10px] bg-blue-100 text-blue-600 px-1 rounded">array</span>
        </div>
        <span class="text-xs text-gray-400">{@field.faker_category}.{@field.faker_function}</span>
        <div :if={has_visible_options?(@field.options)} class="mt-0.5 flex flex-wrap gap-1">
          <span :for={{k, v} <- @field.options || %{}} :if={v != "" && v != nil && k not in ["is_array", "array_count"]} class="text-[10px] bg-white px-1.5 py-0.5 rounded text-gray-500 border border-smoke">
            {k}: {truncate_option(v)}
          </span>
        </div>
      </div>
      <div class="flex items-center gap-1 shrink-0 opacity-0 group-hover:opacity-100 transition">
        <button phx-click="open_field_modal" phx-value-mode="edit" phx-value-index={@idx} class="text-gray-400 hover:text-cypress transition">
          <.icon name="hero-pencil" class="w-3.5 h-3.5" />
        </button>
        <button phx-click="remove_field" phx-value-index={@idx} class="text-gray-400 hover:text-red-500 transition" data-confirm="Remove this field?">
          <.icon name="hero-trash" class="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
    """
  end

  attr :mode, :string, required: true
  attr :prefix, :string, required: true
  attr :fm_name, :string, required: true
  attr :fm_category, :string, required: true
  attr :fm_function, :string, required: true
  attr :fm_functions, :list, required: true
  attr :fm_options_schema, :list, required: true
  attr :fm_options, :map, required: true
  attr :categories, :list, required: true

  defp field_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center" phx-window-keydown="close_field_modal" phx-key="Escape">
      <div class="fixed inset-0 bg-black/50" phx-click="close_field_modal"></div>
      <div class="relative bg-white rounded-xl shadow-xl p-6 w-full max-w-lg mx-4 z-10 max-h-[85vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h2 class="text-lg font-semibold text-peppercorn">
              {if @mode == "add", do: "Add Field", else: "Edit Field"}
            </h2>
            <p :if={@prefix != ""} class="text-sm text-purple-500 mt-0.5">
              <.icon name="hero-folder" class="w-3.5 h-3.5 inline" /> in <strong>{@prefix}</strong>
            </p>
          </div>
          <button phx-click="close_field_modal" class="text-gray-400 hover:text-gray-600">
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        </div>

        <form id="field-modal-form" phx-change="field_modal_change" phx-submit="field_modal_submit">
          <input type="hidden" name="field[prefix]" value={@prefix} />
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Field Name</label>
              <div class="flex items-center gap-1">
                <span :if={@prefix != ""} class="text-sm text-purple-500 font-mono shrink-0">{@prefix}.</span>
                <input type="text" name="field[name]" value={@fm_name} placeholder="e.g. street, city, price" class="input input-bordered w-full" required />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Category</label>
                <select name="field[faker_category]" class="select select-bordered w-full">
                  <option value="">Select...</option>
                  <option :for={cat <- @categories} value={cat} selected={@fm_category == cat}>{cat}</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Generator</label>
                <select name="field[faker_function]" class="select select-bordered w-full" disabled={@fm_category == ""}>
                  <option value="">Select...</option>
                  <option :for={{fname, fdesc} <- @fm_functions} value={fname} selected={@fm_function == fname}>{fname} — {fdesc}</option>
                </select>
              </div>
            </div>

            <div :if={@fm_options_schema != []} class="space-y-2 p-3 bg-smoke/30 rounded-lg">
              <p class="text-xs font-semibold text-gray-500 uppercase tracking-wider">Options</p>
              <div :for={{key, label, type, default} <- @fm_options_schema}>
                <label class="text-sm text-gray-600">{label}</label>
                <%= if type == :textarea do %>
                  <textarea name={"field[options][#{key}]"} class="textarea textarea-bordered textarea-sm w-full font-mono text-xs mt-0.5" rows="3" placeholder={to_string(default)}>{@fm_options[key] || to_string(default)}</textarea>
                <% else %>
                  <input type={option_input_type(type)} name={"field[options][#{key}]"} value={@fm_options[key] || to_string(default)} placeholder={to_string(default)} class="input input-bordered input-sm w-full mt-0.5" step={if type == :float, do: "0.01"} />
                <% end %>
              </div>
            </div>

            <div class="p-3 bg-blue-50/50 rounded-lg space-y-2">
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" name="field[options][is_array]" value="true" checked={@fm_options["is_array"] == "true"} class="checkbox checkbox-sm" />
                <span class="text-sm text-gray-700">Generate as array</span>
              </label>
              <div :if={@fm_options["is_array"] == "true"} class="flex items-center gap-3 flex-wrap">
                <label class="flex items-center gap-1.5">
                  <input type="radio" name="field[options][array_count_mode]" value="fixed" checked={(@fm_options["array_count_mode"] || "fixed") == "fixed"} class="radio radio-sm" />
                  <span class="text-sm text-gray-600">Fixed</span>
                  <input type="number" name="field[options][array_count]" value={@fm_options["array_count"] || "3"} min="1" max="50" class="input input-bordered input-sm w-16" />
                </label>
                <label class="flex items-center gap-1.5">
                  <input type="radio" name="field[options][array_count_mode]" value="range" checked={@fm_options["array_count_mode"] == "range"} class="radio radio-sm" />
                  <span class="text-sm text-gray-600">Range</span>
                  <input type="number" name="field[options][array_min]" value={@fm_options["array_min"] || "1"} min="0" max="50" class="input input-bordered input-sm w-14" placeholder="min" />
                  <span class="text-gray-400">-</span>
                  <input type="number" name="field[options][array_max]" value={@fm_options["array_max"] || "5"} min="1" max="50" class="input input-bordered input-sm w-14" placeholder="max" />
                </label>
              </div>
            </div>
          </div>

          <div class="mt-6 flex items-center gap-3">
            <button type="submit" class="btn btn-primary" disabled={@fm_category == "" || @fm_function == ""}>
              {if @mode == "add", do: "Add Field", else: "Save Changes"}
            </button>
            <button type="button" phx-click="close_field_modal" class="text-sm text-gray-500 hover:underline">Cancel</button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  # ══════════════════════════════════════════════════════════════════════
  # Mount
  # ══════════════════════════════════════════════════════════════════════

  @impl true
  def mount(%{"collection_id" => collection_id, "id" => id}, _session, socket) do
    user = socket.assigns.current_scope.user
    collection = Mocks.get_user_collection!(user.id, collection_id)
    resource = Mocks.get_resource!(id)

    {:ok,
     socket
     |> assign(
       collection_id: String.to_integer(collection_id),
       collection_slug: collection.slug,
       resource: resource,
       fields: to_field_list(resource),
       username: user.username,
       base_url: FakrWeb.Endpoint.url(),
       categories: FakerRegistry.categories(),
       preview_json: nil,
       # Field modal
       field_modal: false,
       field_modal_mode: "add",
       field_modal_edit_index: nil,
       fm_prefix: "",
       fm_name: "",
       fm_category: "",
       fm_function: "",
       fm_functions: [],
       fm_options_schema: [],
       fm_options: %{},
       # Group modals
       group_modal: false,
       group_edit_modal: false,
       ge_group_name: "",
       ge_is_array: false,
       ge_count_mode: "fixed",
       ge_count: "3",
       ge_range_min: "1",
       ge_range_max: "5",
       # Edit resource
       show_edit_resource: false,
       resource_form: to_form(Mocks.change_resource(resource), as: "resource"),
       page_title: "#{resource.name} — Edit"
     )}
  end

  # ══════════════════════════════════════════════════════════════════════
  # Auto-save helper
  # ══════════════════════════════════════════════════════════════════════

  defp auto_save(socket, new_fields) do
    resource = socket.assigns.resource

    field_params =
      Enum.map(new_fields, fn f ->
        Map.take(f, [:name, :faker_category, :faker_function, :options])
      end)

    case Mocks.save_resource_fields(resource, field_params) do
      {:ok, updated_resource} ->
        assign(socket, resource: updated_resource, fields: to_field_list(updated_resource), preview_json: nil)

      {:error, _} ->
        put_flash(socket, :error, "Failed to save.")
    end
  end

  defp to_field_list(resource) do
    Mocks.list_resource_fields(resource.id)
    |> Enum.map(fn f ->
      %{name: f.name, faker_category: f.faker_category, faker_function: f.faker_function, options: f.options || %{}}
    end)
  end

  # ══════════════════════════════════════════════════════════════════════
  # Field Modal
  # ══════════════════════════════════════════════════════════════════════

  @impl true
  def handle_event("open_field_modal", %{"mode" => "add"} = params, socket) do
    prefix = params["prefix"] || ""

    {:noreply,
     assign(socket,
       field_modal: true, field_modal_mode: "add", field_modal_edit_index: nil,
       fm_prefix: prefix, fm_name: "", fm_category: "", fm_function: "",
       fm_functions: [], fm_options_schema: [], fm_options: %{}
     )}
  end

  def handle_event("open_field_modal", %{"mode" => "edit", "index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    field = Enum.at(socket.assigns.fields, idx)
    {prefix, bare} = split_field_name(field.name)
    functions = FakerRegistry.functions_for_category(field.faker_category)
    opts_schema = FakerRegistry.options_for_function(field.faker_category, field.faker_function)

    {:noreply,
     assign(socket,
       field_modal: true, field_modal_mode: "edit", field_modal_edit_index: idx,
       fm_prefix: prefix, fm_name: bare, fm_category: field.faker_category,
       fm_function: field.faker_function, fm_functions: functions,
       fm_options_schema: opts_schema, fm_options: field.options || %{}
     )}
  end

  def handle_event("close_field_modal", _params, socket), do: {:noreply, assign(socket, field_modal: false)}

  def handle_event("field_modal_change", %{"field" => params}, socket) do
    category = params["faker_category"] || socket.assigns.fm_category
    function = params["faker_function"] || socket.assigns.fm_function
    options = Map.merge(socket.assigns.fm_options, params["options"] || %{})

    options =
      if params["options"] && !Map.has_key?(params["options"], "is_array"),
        do: Map.put(options, "is_array", "false"),
        else: options

    {functions, function, opts_schema} =
      cond do
        category != socket.assigns.fm_category ->
          {FakerRegistry.functions_for_category(category), "", []}
        function != socket.assigns.fm_function && function != "" ->
          {socket.assigns.fm_functions, function, FakerRegistry.options_for_function(category, function)}
        true ->
          {socket.assigns.fm_functions, function, socket.assigns.fm_options_schema}
      end

    {:noreply,
     assign(socket,
       fm_name: params["name"] || socket.assigns.fm_name,
       fm_category: category, fm_function: function, fm_functions: functions,
       fm_options_schema: opts_schema, fm_options: options
     )}
  end

  def handle_event("field_modal_submit", %{"field" => params}, socket) do
    bare_name = String.trim(params["name"] || "")
    prefix = params["prefix"] || ""
    full_name = if prefix == "", do: bare_name, else: "#{prefix}.#{bare_name}"
    category = params["faker_category"] || ""
    function = params["faker_function"] || ""
    options = clean_options(params["options"] || %{})

    cond do
      bare_name == "" -> {:noreply, put_flash(socket, :error, "Field name is required.")}
      String.downcase(full_name) == "id" -> {:noreply, put_flash(socket, :error, "\"id\" is reserved.")}
      category == "" || function == "" -> {:noreply, put_flash(socket, :error, "Select a category and generator.")}
      true ->
        new_field = %{name: full_name, faker_category: category, faker_function: function, options: options}

        {result, fields} =
          case socket.assigns.field_modal_mode do
            "add" ->
              if Enum.any?(socket.assigns.fields, &(&1.name == full_name)),
                do: {:dup, nil},
                else: {:ok, socket.assigns.fields ++ [new_field]}
            "edit" ->
              idx = socket.assigns.field_modal_edit_index
              old_name = Enum.at(socket.assigns.fields, idx).name
              if full_name != old_name && Enum.any?(socket.assigns.fields, &(&1.name == full_name)),
                do: {:dup, nil},
                else: {:ok, List.replace_at(socket.assigns.fields, idx, new_field)}
          end

        case result do
          :dup -> {:noreply, put_flash(socket, :error, "Field \"#{full_name}\" already exists.")}
          :ok -> {:noreply, socket |> auto_save(fields) |> assign(field_modal: false)}
        end
    end
  end

  # ══════════════════════════════════════════════════════════════════════
  # Group Modal
  # ══════════════════════════════════════════════════════════════════════

  def handle_event("open_group_modal", _params, socket), do: {:noreply, assign(socket, group_modal: true)}
  def handle_event("close_group_modal", _params, socket), do: {:noreply, assign(socket, group_modal: false)}

  def handle_event("create_group", %{"group_name" => name}, socket) do
    name = String.trim(name)

    cond do
      name == "" ->
        {:noreply, put_flash(socket, :error, "Group name is required.")}
      String.contains?(name, ".") ->
        {:noreply, put_flash(socket, :error, "Group name cannot contain dots.")}
      true ->
        # Close group modal, open field modal with prefix set
        {:noreply,
         assign(socket,
           group_modal: false,
           field_modal: true, field_modal_mode: "add", field_modal_edit_index: nil,
           fm_prefix: name, fm_name: "", fm_category: "", fm_function: "",
           fm_functions: [], fm_options_schema: [], fm_options: %{}
         )}
    end
  end

  # ══════════════════════════════════════════════════════════════════════
  # Field operations
  # ══════════════════════════════════════════════════════════════════════

  def handle_event("remove_field", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    fields = List.delete_at(socket.assigns.fields, idx)
    {:noreply, auto_save(socket, fields)}
  end

  def handle_event("delete_group", %{"group" => group_name}, socket) do
    fields = Enum.reject(socket.assigns.fields, fn f ->
      String.starts_with?(f.name, group_name <> ".") || f.name == "__group_meta.#{group_name}"
    end)

    {:noreply, auto_save(socket, fields)}
  end

  # ── Group settings ──

  def handle_event("edit_group", %{"group" => group_name}, socket) do
    meta = get_group_meta(socket.assigns.fields, group_name)

    {:noreply,
     assign(socket,
       group_edit_modal: true,
       ge_group_name: group_name,
       ge_is_array: meta.is_array,
       ge_count_mode: meta.count_mode,
       ge_count: to_string(meta.count),
       ge_range_min: to_string(meta.min),
       ge_range_max: to_string(meta.max)
     )}
  end

  def handle_event("close_group_edit", _params, socket), do: {:noreply, assign(socket, group_edit_modal: false)}

  def handle_event("group_edit_change", params, socket) do
    is_array = params["group_type"] == "array"

    {:noreply,
     assign(socket,
       ge_is_array: is_array,
       ge_count_mode: params["count_mode"] || socket.assigns.ge_count_mode,
       ge_count: params["count"] || socket.assigns.ge_count,
       ge_range_min: params["range_min"] || socket.assigns.ge_range_min,
       ge_range_max: params["range_max"] || socket.assigns.ge_range_max
     )}
  end

  def handle_event("save_group_settings", params, socket) do
    group_name = params["group_name"]
    is_array = params["group_type"] == "array"

    meta_options =
      if is_array do
        %{
          "is_group_array" => "true",
          "count_mode" => params["count_mode"] || "fixed",
          "count" => params["count"] || "3",
          "range_min" => params["range_min"] || "1",
          "range_max" => params["range_max"] || "5"
        }
      else
        %{"is_group_array" => "false"}
      end

    meta_field_name = "__group_meta.#{group_name}"

    meta_field = %{
      name: meta_field_name,
      faker_category: "Custom",
      faker_function: "pick",
      options: Map.put(meta_options, "items", "__meta__")
    }

    # Update or insert the meta field
    fields =
      socket.assigns.fields
      |> Enum.reject(&(&1.name == meta_field_name))
      |> then(&(&1 ++ [meta_field]))

    {:noreply,
     socket
     |> auto_save(fields)
     |> assign(group_edit_modal: false)}
  end

  def handle_event("reorder_nodes", %{"order" => order}, socket) do
    fields = socket.assigns.fields

    new_fields =
      Enum.flat_map(order, fn node_id ->
        case String.split(node_id, ":", parts: 2) do
          ["field", name] ->
            Enum.filter(fields, &(&1.name == name))

          ["group", group_name] ->
            # Collect all fields belonging to this group (including meta)
            Enum.filter(fields, fn f ->
              String.starts_with?(f.name, group_name <> ".") ||
                f.name == "__group_meta.#{group_name}"
            end)

          _ ->
            []
        end
      end)

    # Append any fields not covered (safety net)
    covered_names = MapSet.new(new_fields, & &1.name)
    remaining = Enum.reject(fields, &MapSet.member?(covered_names, &1.name))

    {:noreply, auto_save(socket, new_fields ++ remaining)}
  end

  # ══════════════════════════════════════════════════════════════════════
  # Revert
  # ══════════════════════════════════════════════════════════════════════

  def handle_event("revert_to_published", _params, socket) do
    case Mocks.revert_resource_to_published(socket.assigns.resource) do
      {:ok, reverted} ->
        {:noreply,
         socket
         |> assign(resource: reverted, fields: to_field_list(reverted), preview_json: nil)
         |> put_flash(:info, "Reverted to Rev. #{reverted.revision}")}
      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  # ══════════════════════════════════════════════════════════════════════
  # Preview
  # ══════════════════════════════════════════════════════════════════════

  def handle_event("generate_preview", _params, socket) do
    fields =
      Enum.map(socket.assigns.fields, fn f ->
        %ResourceField{name: f.name, faker_category: f.faker_category, faker_function: f.faker_function, options: f.options || %{}}
      end)

    preview = Mocks.generate_preview(fields)
    json = Jason.encode!(preview, pretty: true)
    {:noreply, assign(socket, preview_json: json)}
  end

  # ══════════════════════════════════════════════════════════════════════
  # Edit Resource
  # ══════════════════════════════════════════════════════════════════════

  def handle_event("open_edit_resource", _params, socket) do
    {:noreply, assign(socket, show_edit_resource: true, resource_form: to_form(Mocks.change_resource(socket.assigns.resource), as: "resource"))}
  end

  def handle_event("close_edit_resource", _params, socket), do: {:noreply, assign(socket, show_edit_resource: false)}

  def handle_event("update_resource", %{"resource" => params}, socket) do
    case Mocks.update_resource(socket.assigns.resource, params) do
      {:ok, resource} ->
        resource = Mocks.get_resource!(resource.id)
        {:noreply, socket |> assign(resource: resource, show_edit_resource: false) |> put_flash(:info, "Resource updated.")}
      {:error, changeset} ->
        {:noreply, assign(socket, resource_form: to_form(changeset, as: "resource"))}
    end
  end

  # ══════════════════════════════════════════════════════════════════════
  # Tree builder
  # ══════════════════════════════════════════════════════════════════════

  defp build_field_tree(fields) do
    # Filter out meta fields for display
    visible_fields = Enum.reject(fields, &String.starts_with?(&1.name, "__group_meta."))

    {root_fields, grouped} =
      visible_fields
      |> Enum.with_index()
      |> Enum.map(fn {f, _} -> {f, field_index(fields, f.name)} end)
      |> Enum.split_with(fn {f, _idx} -> !String.contains?(f.name, ".") end)

    group_order =
      grouped
      |> Enum.map(fn {f, _} -> f.name |> String.split(".", parts: 2) |> hd() end)
      |> Enum.uniq()

    groups =
      Enum.map(group_order, fn prefix ->
        children =
          Enum.filter(grouped, fn {f, _} -> String.starts_with?(f.name, prefix <> ".") end)
          |> Enum.map(fn {f, idx} -> {:field, idx, f} end)

        meta = get_group_meta(fields, prefix)
        {:group, prefix, children, meta}
      end)

    root = Enum.map(root_fields, fn {f, idx} -> {:field, idx, f} end)

    (root ++ groups)
    |> Enum.sort_by(fn
      {:field, idx, _} -> idx
      {:group, _, [{:field, first_idx, _} | _], _} -> first_idx
      {:group, _, _, _} -> 999_999
    end)
  end

  defp field_index(fields, name) do
    Enum.find_index(fields, &(&1.name == name)) || 0
  end

  defp get_group_meta(fields, group_name) do
    meta_field = Enum.find(fields, &(&1.name == "__group_meta.#{group_name}"))

    if meta_field && meta_field.options["is_group_array"] == "true" do
      %{
        is_array: true,
        count_mode: meta_field.options["count_mode"] || "fixed",
        count: meta_field.options["count"] || "3",
        min: meta_field.options["range_min"] || "1",
        max: meta_field.options["range_max"] || "5"
      }
    else
      %{is_array: false, count_mode: "fixed", count: "3", min: "1", max: "5"}
    end
  end


  # ══════════════════════════════════════════════════════════════════════
  # Helpers
  # ══════════════════════════════════════════════════════════════════════

  defp split_field_name(name) do
    case String.split(name, ".", parts: 2) do
      [prefix, bare] -> {prefix, bare}
      [bare] -> {"", bare}
    end
  end

  defp display_name(name) do
    case String.split(name, ".", parts: 2) do
      [_, bare] -> bare
      [bare] -> bare
    end
  end

  defp clean_options(opts), do: for({k, v} <- opts, v != "", into: %{}, do: {k, v})

  defp option_input_type(:integer), do: "number"
  defp option_input_type(:float), do: "number"
  defp option_input_type(_), do: "text"

  defp truncate_option(v) when is_binary(v), do: if(String.length(v) > 25, do: String.slice(v, 0, 22) <> "...", else: v)
  defp truncate_option(v), do: to_string(v)

  defp has_visible_options?(nil), do: false
  defp has_visible_options?(opts), do: Enum.any?(opts, fn {k, v} -> v != "" && v != nil && k not in ["is_array", "array_count"] end)

  attr :path, :string, required: true
  attr :base_url, :string, required: true

  defp endpoint_row(assigns) do
    assigns = assign(assigns, full_url: assigns.base_url <> assigns.path)

    ~H"""
    <div class="bg-peppercorn rounded-lg px-3 py-2 space-y-1">
      <div class="flex items-center gap-2">
        <span class="text-xs font-bold text-cavendish bg-cavendish/20 px-1.5 py-0.5 rounded">GET</span>
        <code class="text-sm text-green-400 font-mono flex-1 truncate">{@path}</code>
        <button phx-click={JS.dispatch("phx:copy", detail: %{text: @full_url})} class="text-gray-500 hover:text-cavendish transition shrink-0" title="Copy"><.icon name="hero-clipboard" class="w-4 h-4" /></button>
      </div>
      <p class="text-[11px] text-gray-500 font-mono truncate">{@full_url}</p>
    </div>
    """
  end
end
