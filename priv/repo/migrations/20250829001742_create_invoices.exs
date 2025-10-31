defmodule Billing.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:quotes) do
      add :customer_id, references(:customers, on_delete: :delete_all)
      add :issued_at, :date
      add :due_date, :date
      add :amount, :decimal, precision: 10, scale: 2
      add :description, :text
      add :tax_rate, :decimal, precision: 5, scale: 2
      add :amount_with_tax, :decimal, precision: 10, scale: 2
      add :payment_method, :string

      timestamps(type: :utc_datetime)
    end

    create index(:quotes, [:customer_id])
  end
end
