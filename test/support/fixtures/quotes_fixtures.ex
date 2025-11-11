defmodule Billing.QuotesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Billing.Quotes` context.
  """

  import Billing.CustomersFixtures
  import Billing.EmissionProfilesFixtures

  @doc """
  Generate a quote.
  """
  def quote_fixture(scope, attrs \\ %{}) do
    customer = customer_fixture(scope)
    emission_profile = emission_profile_fixture(scope)

    attrs =
      attrs
      |> Enum.into(%{
        customer_id: customer.id,
        emission_profile_id: emission_profile.id,
        issued_at: ~D[2025-08-28],
        description: "Invoice Test",
        due_date: ~D[2025-08-28],
        amount: Decimal.new("10.0"),
        tax_rate: Decimal.new("15.0"),
        payment_method: :cash,
        items: [
          %{
            description: "Product",
            price: Decimal.new("10.0"),
            amount: Decimal.new("10.0"),
            tax_rate: Decimal.new("15.0")
          }
        ]
      })

    {:ok, quote} = Billing.Quotes.create_quote(scope, attrs)

    quote
  end
end
