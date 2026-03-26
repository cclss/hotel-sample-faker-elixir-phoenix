defmodule Fakr.Mocks.ResourceField do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resource_fields" do
    field :name, :string
    field :faker_category, :string
    field :faker_function, :string
    field :options, :map, default: %{}
    field :position, :integer, default: 0

    belongs_to :resource, Fakr.Mocks.Resource

    timestamps(type: :utc_datetime)
  end

  def changeset(field, attrs) do
    field
    |> cast(attrs, [:name, :faker_category, :faker_function, :options, :position])
    |> validate_required([:name, :faker_category, :faker_function])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_reserved_name()
    |> validate_faker_generator()
    |> unique_constraint([:resource_id, :name], message: "already exists in this resource")
  end

  @reserved_names ~w(id)

  defp validate_reserved_name(changeset) do
    name = get_change(changeset, :name)

    if name && String.downcase(String.trim(name)) in @reserved_names do
      add_error(changeset, :name, "\"#{name}\" is reserved — it is auto-generated for every record")
    else
      changeset
    end
  end

  defp validate_faker_generator(changeset) do
    category = get_field(changeset, :faker_category)
    function = get_field(changeset, :faker_function)

    if category && function do
      if Fakr.Mocks.FakerRegistry.valid_generator?(category, function) do
        changeset
      else
        add_error(changeset, :faker_function, "is not valid for the selected category")
      end
    else
      changeset
    end
  end
end
