defmodule Billing.ProductsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Billing.Products` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        name: "some name",
        price: "120.50"
      })
      |> Billing.Products.create_product()

    product
  end
end
