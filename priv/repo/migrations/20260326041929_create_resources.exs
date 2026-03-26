defmodule Fakr.Repo.Migrations.CreateResources do
  use Ecto.Migration

  def change do
    create table(:resources) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :total_records, :integer, null: false, default: 25
      add :published, :boolean, default: false, null: false
      add :collection_id, references(:collections, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:resources, [:collection_id])
    create unique_index(:resources, [:collection_id, :slug])
  end
end
