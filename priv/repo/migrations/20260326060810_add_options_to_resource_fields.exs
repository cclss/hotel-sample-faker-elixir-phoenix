defmodule Fakr.Repo.Migrations.AddOptionsToResourceFields do
  use Ecto.Migration

  def change do
    alter table(:resource_fields) do
      add :options, :map, default: %{}
    end
  end
end
