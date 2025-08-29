defmodule Billing.Invoices.Invoice do
  use Ecto.Schema
  import Ecto.Changeset

  schema "invoices" do
    belongs_to :customer, Billing.Customers.Customer

    field :issued_at, :date
    field :description, :string
    field :due_date, :date
    field :amount, :decimal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [:customer_id, :issued_at, :description, :due_date, :amount])
    |> validate_required([:customer_id, :issued_at, :description, :due_date, :amount])
  end
end
