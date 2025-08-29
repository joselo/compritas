defmodule Billing.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:invoices) do
      add :customer_id, references(:customers, on_delete: :delete_all)
      add :issued_at, :date
      add :due_date, :date
      add :amount, :decimal, precision: 10, scale: 2
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create index(:invoices, [:customer_id])
  end
end
