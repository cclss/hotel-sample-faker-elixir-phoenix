defmodule Fakr.Repo.Migrations.CreateGeneratedRecords do
  use Ecto.Migration

  def change do
    create table(:generated_records) do
      add :data, :map, null: false
      add :record_index, :integer, null: false
      add :resource_id, references(:resources, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:generated_records, [:resource_id])
    create unique_index(:generated_records, [:resource_id, :record_index])
  end
end
