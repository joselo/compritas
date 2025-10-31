defmodule Billing.Repo.Migrations.ElectronicInvoices do
  use Ecto.Migration

  def change do
    create table(:electronic_invoices) do
      add :quote_id, references(:quotes, on_delete: :delete_all)
      add :access_key, :string
      add :state, :string

      timestamps(type: :utc_datetime)
    end

    create index(:electronic_invoices, [:quote_id])
  end
end
