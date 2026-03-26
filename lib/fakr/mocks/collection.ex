defmodule Fakr.Mocks.Collection do
  use Ecto.Schema
  import Ecto.Changeset

  schema "collections" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :published, :boolean, default: false
    field :explorable, :boolean, default: false

    belongs_to :user, Fakr.Accounts.User
    has_many :resources, Fakr.Mocks.Resource

    timestamps(type: :utc_datetime)
  end

  def changeset(collection, attrs) do
    collection
    |> cast(attrs, [:name, :description, :explorable])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> generate_slug()
    |> unique_constraint([:user_id, :slug])
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      name ->
        slug =
          name
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9\s-]/, "")
          |> String.replace(~r/[\s]+/, "-")
          |> String.trim("-")

        put_change(changeset, :slug, slug)
    end
  end
end
