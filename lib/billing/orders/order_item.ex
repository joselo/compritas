defmodule Billing.Orders.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Billing.Orders.Order

  schema "order_items" do
    belongs_to :order, Order

    field :name, :string
    field :price, :decimal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:name, :price])
    |> validate_required([:name, :price])
  end
end
