defmodule Fakr.Repo.Migrations.AddPublishedSchemaToResources do
  use Ecto.Migration

  def change do
    alter table(:resources) do
      add :published_schema, :map
    end
  end
end
