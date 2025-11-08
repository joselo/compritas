defmodule Billing.Repo.Migrations.AddAmountToElectronicInvoices do
  use Ecto.Migration

  def change do
    alter table(:electronic_invoices) do
      add :amount, :decimal, precision: 10, scale: 2, default: 0
    end
  end
end
