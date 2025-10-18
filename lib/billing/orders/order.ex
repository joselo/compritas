defmodule Billing.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias Billing.Carts.Cart

  schema "orders" do
    field :cart_uuid, Ecto.UUID
    field :full_name, :string
    field :phone_number, :string

    has_many :items, Cart, foreign_key: :cart_uuid, references: :cart_uuid

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:cart_uuid, :full_name, :phone_number])
    |> validate_required([:cart_uuid, :full_name, :phone_number])
  end
end
