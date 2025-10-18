defmodule Billing.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias Billing.Orders.OrderItem

  schema "orders" do
    field :full_name, :string
    field :phone_number, :string

    timestamps(type: :utc_datetime)

    has_many :items, OrderItem, foreign_key: :order_id
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:full_name, :phone_number])
    |> validate_required([:full_name, :phone_number])
    |> cast_assoc(:items)
  end
end
