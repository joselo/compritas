defmodule Billing.Repo.Migrations.AddUserIdToTables do
  use Ecto.Migration

  def change do
    alter table(:certificates) do
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
    end

    alter table(:chat_messages) do
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
    end

    alter table(:companies) do
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
    end

    alter table(:customers) do
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
    end

    alter table(:electronic_invoices) do
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
    end

    alter table(:emission_profiles) do
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
    end

    alter table(:order_items) do
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
    end

    alter table(:orders) do
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
    end

    alter table(:products) do
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
    end

    alter table(:quote_items) do
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
    end

    alter table(:quotes) do
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
    end

    alter table(:settings) do
      add :user_id, references(:users, type: :id, on_delete: :delete_all)
    end

    create index(:certificates, [:user_id])
    create index(:chat_messages, [:user_id])
    create index(:companies, [:user_id])
    create index(:customers, [:user_id])
    create index(:electronic_invoices, [:user_id])
    create index(:emission_profiles, [:user_id])
    create index(:order_items, [:user_id])
    create index(:orders, [:user_id])
    create index(:products, [:user_id])
    create index(:quote_items, [:user_id])
    create index(:quotes, [:user_id])
    create index(:settings, [:user_id])
  end
end
