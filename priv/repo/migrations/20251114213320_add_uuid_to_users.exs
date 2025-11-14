defmodule Billing.Repo.Migrations.AddUuidToUsers do
  use Ecto.Migration

  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pgcrypto"

    alter table(:users) do
      add :uuid, :uuid, null: false, default: fragment("gen_random_uuid()")
    end

    create unique_index(:users, [:uuid])
  end

  def down do
    drop index(:users, [:uuid])

    alter table(:users) do
      remove :uuid
    end
  end
end
