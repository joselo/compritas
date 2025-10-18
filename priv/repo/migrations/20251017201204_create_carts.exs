defmodule Billing.Repo.Migrations.CreateCarts do
  use Ecto.Migration

  def change do
    create table(:carts) do
      add :cart_uuid, :uuid
      add :product_name, :string
      add :product_price, :decimal, precision: 10, scale: 2

      timestamps(type: :utc_datetime)
    end

    create unique_index(:carts, [:cart_uuid])
  end
end
