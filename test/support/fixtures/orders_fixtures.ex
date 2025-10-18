defmodule Billing.OrdersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Billing.Orders` context.
  """

  @doc """
  Generate a order.
  """
  def order_fixture(attrs \\ %{}) do
    {:ok, order} =
      attrs
      |> Enum.into(%{
        cart_uuid: "7488a646-e31f-11e4-aace-600308960662",
        full_name: "some full_name",
        phone_number: "some phone_number"
      })
      |> Billing.Orders.create_order()

    order
  end
end
