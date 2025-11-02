defmodule Billing.Repo.Migrations.CreateQuoteItems do
  use Ecto.Migration

  def change do
    create table(:quote_items) do
      add :quote_id, references(:quotes, on_delete: :delete_all)
      add :description, :text, null: false
      add :amount, :decimal, precision: 10, scale: 2, null: false
      add :tax_rate, :decimal, precision: 10, scale: 2
      add :amount_without_tax, :decimal, precision: 10, scale: 2

      timestamps(type: :utc_datetime)
    end

    create index(:quote_items, [:quote_id])
  end
end
