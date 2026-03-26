defmodule Fakr.Repo.Migrations.CreateCollections do
  use Ecto.Migration

  def change do
    create table(:collections) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :published, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:collections, [:user_id])
    create unique_index(:collections, [:user_id, :slug])
  end
end
