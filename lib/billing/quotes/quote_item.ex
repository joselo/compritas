defmodule Billing.Quotes.QuoteItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Billing.Quotes.Quote

  schema "quote_items" do
    belongs_to :quote, Quote

    field :description, :string
    field :amount, :decimal, default: 0.0
    field :tax_rate, :decimal, default: 15.0
    field :price, :decimal
    field :quantity, :decimal, default: 1.0
    field :amount_without_tax, :decimal
    field :user_id, :id

    field :marked_for_deletion, :boolean, virtual: true, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quote_item, attrs, user_scope) do
    quote_item
    |> cast(attrs, [:description, :price, :quantity, :tax_rate, :marked_for_deletion])
    |> validate_required([:description, :price, :quantity, :tax_rate])
    |> put_change(:user_id, user_scope.user.id)
  end
end
