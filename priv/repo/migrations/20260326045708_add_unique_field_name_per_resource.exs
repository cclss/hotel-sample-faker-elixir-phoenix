defmodule Fakr.Repo.Migrations.AddUniqueFieldNamePerResource do
  use Ecto.Migration

  def change do
    create unique_index(:resource_fields, [:resource_id, :name])
  end
end
