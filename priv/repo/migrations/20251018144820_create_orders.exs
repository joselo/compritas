defmodule Billing.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :cart_uuid, :uuid
      add :full_name, :string
      add :phone_number, :string

      timestamps(type: :utc_datetime)
    end
  end
end
