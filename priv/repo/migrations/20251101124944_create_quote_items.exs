defmodule Billing.Repo.Migrations.CreateQuoteItems do
  use Ecto.Migration

  def change do
    create table(:quote_items) do
      add :quote_id, references(:quotes, on_delete: :delete_all)
      add :name, :string, null: false
      add :amount, :decimal, precision: 10, scale: 2, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:quote_items, [:quote_id])
  end
end
