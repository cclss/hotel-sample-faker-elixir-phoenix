defmodule Fakr.Mocks.GeneratedRecord do
  use Ecto.Schema
  import Ecto.Changeset

  schema "generated_records" do
    field :data, :map
    field :record_index, :integer

    belongs_to :resource, Fakr.Mocks.Resource

    timestamps(type: :utc_datetime)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:data, :record_index, :resource_id])
    |> validate_required([:data, :record_index, :resource_id])
    |> unique_constraint([:resource_id, :record_index])
  end
end
