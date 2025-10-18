defmodule Billing.CartsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Billing.Carts` context.
  """

  @doc """
  Generate a cart.
  """

  def cart_fixture(attrs \\ %{}) do
    {:ok, cart} =
      attrs
      |> Enum.into(%{
        cart_uuid: Ecto.UUID.generate(),
        product_name: "Product",
        product_price: Decimal.new("5.00")
      })
      |> Billing.Carts.create_cart()

    cart
  end
end
