defmodule Billing.ProductsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Billing.Products` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(scope, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        name: "some name",
        price: "120.50"
      })

    {:ok, product} = Billing.Products.create_product(scope, attrs)

    product
  end
end
