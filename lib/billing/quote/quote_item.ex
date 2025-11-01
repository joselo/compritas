defmodule Billing.Quote.QuoteItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quote_items" do
    field :name, :string
    field :amount, :decimal
    field :quote_id, :id
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quote_item, attrs, user_scope) do
    quote_item
    |> cast(attrs, [:name, :amount])
    |> validate_required([:name, :amount])
    |> put_change(:user_id, user_scope.user.id)
  end
end
