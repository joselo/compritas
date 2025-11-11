defmodule Billing.Orders.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Billing.Orders.Order

  schema "order_items" do
    belongs_to :order, Order

    field :name, :string
    field :price, :decimal
    field :quantity, :decimal, default: 1.0
    field :amount, :decimal
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order_item, attrs, user_scope) do
    order_item
    |> cast(attrs, [:name, :price, :quantity])
    |> validate_required([:name, :price, :quantity])
    |> put_change(:user_id, user_scope.user.id)
  end
end
