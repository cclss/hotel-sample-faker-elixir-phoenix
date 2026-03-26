defmodule FakrWeb.CollectionLive.Form do
  use FakrWeb, :live_view

  alias Fakr.Mocks
  alias Fakr.Mocks.Collection

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-xl mx-auto">
        <.link
          navigate={~p"/dashboard"}
          class="text-sm text-blue hover:underline mb-4 inline-block"
        >
          &larr; Back to Dashboard
        </.link>

        <h1 class="text-2xl font-bold text-navy mb-6">
          {if @live_action == :new, do: "New Collection", else: "Edit Collection"}
        </h1>

        <div class="bg-white rounded-xl border border-gray-200 p-6">
          <.form for={@form} id="collection-form" phx-change="validate" phx-submit="save">
            <div class="space-y-4">
              <.input
                field={@form[:name]}
                type="text"
                label="Collection Name"
                placeholder="e.g. E-Commerce API"
                required
                phx-mounted={JS.focus()}
              />

              <div :if={@slug_preview} class="text-sm text-gray-500">
                Slug: <code class="bg-gray-100 px-2 py-1 rounded text-navy">{@slug_preview}</code>
              </div>

              <.input
                field={@form[:description]}
                type="textarea"
                label="Description"
                placeholder="Describe what this collection provides..."
              />

              <label class="flex items-center gap-2 cursor-pointer">
                <input type="hidden" name="collection[explorable]" value="false" />
                <input
                  type="checkbox"
                  name="collection[explorable]"
                  value="true"
                  checked={Phoenix.HTML.Form.input_value(@form, :explorable) == true || Phoenix.HTML.Form.input_value(@form, :explorable) == "true"}
                  class="checkbox checkbox-sm"
                />
                <span class="text-sm text-gray-700">Show in Explore page</span>
              </label>
            </div>

            <div class="mt-6 flex items-center gap-3">
              <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
                {if @live_action == :new, do: "Create Collection", else: "Update Collection"}
              </.button>
              <.link navigate={~p"/dashboard"} class="text-sm text-gray-500 hover:underline">
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
    user = socket.assigns.current_scope.user

    {collection, changeset} =
      case socket.assigns.live_action do
        :new ->
          {%Collection{}, Mocks.change_collection(%Collection{})}

        :edit ->
          collection = Mocks.get_user_collection!(user.id, params["id"])
          {collection, Mocks.change_collection(collection)}
      end

    slug_preview = collection.slug || ""

    {:ok,
     socket
     |> assign(
       collection: collection,
       slug_preview: slug_preview,
       page_title:
         if(socket.assigns.live_action == :new, do: "New Collection", else: "Edit Collection")
     )
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"collection" => params}, socket) do
    changeset =
      socket.assigns.collection
      |> Mocks.change_collection(params)
      |> Map.put(:action, :validate)

    slug_preview = Ecto.Changeset.get_field(changeset, :slug) || ""

    {:noreply,
     socket
     |> assign(slug_preview: slug_preview)
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"collection" => params}, socket) do
    user = socket.assigns.current_scope.user

    case socket.assigns.live_action do
      :new ->
        case Mocks.create_collection(user, params) do
          {:ok, collection} ->
            {:noreply,
             socket
             |> put_flash(:info, "Collection created successfully!")
             |> push_navigate(to: ~p"/collections/#{collection.id}")}

          {:error, changeset} ->
            {:noreply, assign_form(socket, changeset)}
        end

      :edit ->
        case Mocks.update_collection(socket.assigns.collection, params) do
          {:ok, collection} ->
            {:noreply,
             socket
             |> put_flash(:info, "Collection updated successfully!")
             |> push_navigate(to: ~p"/collections/#{collection.id}")}

          {:error, changeset} ->
            {:noreply, assign_form(socket, changeset)}
        end
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, form: to_form(changeset, as: "collection"))
  end
end
