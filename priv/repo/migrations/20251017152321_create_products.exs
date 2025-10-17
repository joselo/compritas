defmodule Billing.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :price, :decimal, precision: 10, scale: 2

      timestamps(type: :utc_datetime)
    end
  end
end
