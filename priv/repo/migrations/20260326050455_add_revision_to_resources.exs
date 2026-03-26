defmodule Fakr.Repo.Migrations.AddRevisionToResources do
  use Ecto.Migration

  def change do
    alter table(:resources) do
      add :revision, :integer, null: false, default: 0
      add :revised_at, :utc_datetime
      add :published_revision, :integer
    end
  end
end
