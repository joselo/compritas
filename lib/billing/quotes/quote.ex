defmodule Billing.Quotes.Quote do
  use Ecto.Schema
  import Ecto.Changeset

  alias Billing.Quotes.QuoteItem

  @derive {Jason.Encoder, only: [:amount]}

  schema "quotes" do
    belongs_to :customer, Billing.Customers.Customer
    belongs_to :emission_profile, Billing.EmissionProfiles.EmissionProfile

    has_many :electronic_invoices, Billing.Quotes.ElectronicInvoice
    has_many :items, QuoteItem, foreign_key: :quote_id, on_replace: :delete

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
      :payment_method
    ])
    |> validate_required([
      :customer_id,
      :emission_profile_id,
      :issued_at,
      :description,
      :due_date,
      :payment_method
    ])
    |> cast_assoc(:items)
    |> validate_has_items()
  end

  defp validate_has_items(changeset) do
    items = get_field(changeset, :items, [])

    valid_items =
      Enum.reject(items, fn item ->
        case item do
          %Ecto.Changeset{action: :delete} -> true
          _ -> false
        end
      end)

    if Enum.empty?(valid_items) do
      add_error(changeset, :items, "debe tener al menos un item")
    else
      changeset
    end
  end
end
