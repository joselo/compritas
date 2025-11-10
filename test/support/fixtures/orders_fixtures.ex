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
        full_name: "Sub Zero",
        email: "sub.zero@example.com",
        identification_number: "1234567890",
        identification_type: :cedula,
        address: "Arena",
        phone_number: "123456789",
        items: [
          %{name: "Product", price: Decimal.new("5.00"), quantity: Decimal.new("1.00")}
        ]
      })
      |> Billing.Orders.create_order()

    order
  end
end
