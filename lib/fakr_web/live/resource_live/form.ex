defmodule FakrWeb.ResourceLive.Form do
  use FakrWeb, :live_view

  alias Fakr.Mocks
  alias Fakr.Mocks.Resource

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-xl mx-auto">
        <.link
          navigate={~p"/collections/#{@collection_id}"}
          class="text-sm text-cypress hover:underline mb-4 inline-block"
        >
          &larr; Back to Collection
        </.link>

        <h1 class="text-2xl font-bold text-peppercorn mb-6">
          {if @live_action == :new, do: "New Resource", else: "Edit Resource"}
        </h1>

        <div class="bg-white rounded-xl border border-smoke p-6">
          <.form for={@form} id="resource-form" phx-change="validate" phx-submit="save">
            <div class="space-y-4">
              <.input
                field={@form[:name]}
                type="text"
                label="Resource Name"
                placeholder="e.g. users, products, orders"
                required
                phx-mounted={JS.focus()}
              />

              <div :if={@slug_preview} class="text-sm text-gray-500">
                Slug: <code class="bg-smoke px-2 py-1 rounded text-peppercorn">{@slug_preview}</code>
              </div>

              <.input
                field={@form[:total_records]}
                type="number"
                label="Total Records"
                min="1"
                max="1000"
              />
              <p class="text-xs text-gray-400 -mt-2">Number of mock records to generate (1-1000)</p>
            </div>

            <div class="mt-6 flex items-center gap-3">
              <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
                {if @live_action == :new, do: "Create Resource", else: "Update Resource"}
              </.button>
              <.link
                navigate={~p"/collections/#{@collection_id}"}
                class="text-sm text-gray-500 hover:underline"
              >
                Cancel
              </.link>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    collection_id = params["collection_id"]
    user = socket.assigns.current_scope.user
    _collection = Mocks.get_user_collection!(user.id, collection_id)

    {resource, changeset} =
      case socket.assigns.live_action do
        :new ->
          {%Resource{}, Mocks.change_resource(%Resource{})}

        :edit ->
          resource = Mocks.get_resource!(params["id"])
          {resource, Mocks.change_resource(resource)}
      end

    slug_preview = resource.slug || ""

    {:ok,
     socket
     |> assign(
       collection_id: String.to_integer(collection_id),
       resource: resource,
       slug_preview: slug_preview,
       page_title:
         if(socket.assigns.live_action == :new, do: "New Resource", else: "Edit Resource")
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"resource" => params}, socket) do
    changeset =
      socket.assigns.resource
      |> Mocks.change_resource(params)
      |> Map.put(:action, :validate)

    slug_preview = Ecto.Changeset.get_field(changeset, :slug) || ""

    {:noreply,
     socket
     |> assign(slug_preview: slug_preview)
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"resource" => params}, socket) do
    user = socket.assigns.current_scope.user
    collection = Mocks.get_user_collection!(user.id, socket.assigns.collection_id)

    case socket.assigns.live_action do
      :new ->
        case Mocks.create_resource(collection, params) do
          {:ok, resource} ->
            {:noreply,
             socket
             |> put_flash(:info, "Resource created!")
             |> push_navigate(to: ~p"/collections/#{collection.id}/resources/#{resource.id}")}

          {:error, changeset} ->
            {:noreply, assign_form(socket, changeset)}
        end

      :edit ->
        case Mocks.update_resource(socket.assigns.resource, params) do
          {:ok, _resource} ->
            {:noreply,
             socket
             |> put_flash(:info, "Resource updated!")
             |> push_navigate(to: ~p"/collections/#{collection.id}")}

          {:error, changeset} ->
            {:noreply, assign_form(socket, changeset)}
        end
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, form: to_form(changeset, as: "resource"))
  end
end
