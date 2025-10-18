defmodule Billing.Carts.Cart do
  use Ecto.Schema
  import Ecto.Changeset

  schema "carts" do
    field :cart_uuid, Ecto.UUID
    field :product_name, :string
    field :product_price, :decimal, default: 0.0

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cart, attrs) do
    cart
    |> cast(attrs, [:cart_uuid, :product_name, :product_price])
    |> validate_required([:cart_uuid, :product_name, :product_price])
    |> unique_constraint([:cart_uuid, :product_name, :product_price])
  end
end
