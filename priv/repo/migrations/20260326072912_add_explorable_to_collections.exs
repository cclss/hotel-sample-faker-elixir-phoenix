defmodule Fakr.Repo.Migrations.AddExplorableToCollections do
  use Ecto.Migration

  def change do
    alter table(:collections) do
      add :explorable, :boolean, default: false, null: false
    end

    create index(:collections, [:explorable])
  end
end
