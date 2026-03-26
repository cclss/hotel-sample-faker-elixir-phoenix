defmodule Fakr.Mocks.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resources" do
    field :name, :string
    field :slug, :string
    field :total_records, :integer, default: 25
    field :published, :boolean, default: false
    field :revision, :integer, default: 0
    field :revised_at, :utc_datetime
    field :published_revision, :integer
    field :published_schema, :map

    belongs_to :collection, Fakr.Mocks.Collection
    has_many :fields, Fakr.Mocks.ResourceField
    has_many :generated_records, Fakr.Mocks.GeneratedRecord

    timestamps(type: :utc_datetime)
  end

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:name, :total_records])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_number(:total_records, greater_than: 0, less_than_or_equal_to: 1000)
    |> generate_slug()
    |> unique_constraint([:collection_id, :slug])
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
