defmodule Billing.Quotes.QuoteItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Billing.Quotes.Quote

  schema "quote_items" do
    belongs_to :quote, Quote

    field :name, :string
    field :amount, :decimal
    field :marked_for_deletion, :boolean, virtual: true, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quote_item, attrs) do
    quote_item
    |> cast(attrs, [:name, :amount, :marked_for_deletion])
    |> validate_required([:name, :amount])
  end
end
