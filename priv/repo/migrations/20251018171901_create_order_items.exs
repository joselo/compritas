defmodule Billing.Repo.Migrations.CreateOrderItems do
  use Ecto.Migration

  def change do
    create table(:order_items) do
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :price, :decimal, precision: 10, scale: 2, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:order_items, [:order_id])
  end
end
