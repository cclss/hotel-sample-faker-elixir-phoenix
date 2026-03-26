defmodule Fakr.Repo.Migrations.CreateResourceFields do
  use Ecto.Migration

  def change do
    create table(:resource_fields) do
      add :name, :string, null: false
      add :faker_category, :string, null: false
      add :faker_function, :string, null: false
      add :position, :integer, null: false, default: 0
      add :resource_id, references(:resources, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:resource_fields, [:resource_id])
  end
end
