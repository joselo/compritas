defmodule Billing.Quotes.Quote do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:amount]}

  schema "quotes" do
    belongs_to :customer, Billing.Customers.Customer
    belongs_to :emission_profile, Billing.EmissionProfiles.EmissionProfile

    has_many :electronic_invoices, Billing.Quotes.ElectronicInvoice

    field :issued_at, :date
    field :description, :string
    field :due_date, :date
    field :amount, :decimal
    field :tax_rate, :decimal, default: 15.0
    field :amount_without_tax, :decimal
    field :payment_method, Ecto.Enum, values: [:cash, :credit_card, :bank_transfer]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quote, attrs) do
    quote
    |> cast(attrs, [
      :customer_id,
      :emission_profile_id,
      :issued_at,
      :description,
      :due_date,
      :amount,
      :tax_rate,
      :payment_method
    ])
    |> validate_required([
      :customer_id,
      :emission_profile_id,
      :issued_at,
      :description,
      :due_date,
      :amount,
      :tax_rate,
      :payment_method
    ])
  end
end
