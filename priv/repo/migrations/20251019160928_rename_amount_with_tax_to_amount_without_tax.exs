defmodule Billing.Repo.Migrations.RenameAmountWithTaxToAmountWithoutTax do
  use Ecto.Migration

  def change do
    rename table(:quotes), :amount_with_tax, to: :amount_without_tax
  end
end
