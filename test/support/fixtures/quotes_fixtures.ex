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
  def quote_fixture(attrs \\ %{}) do
    customer = customer_fixture()
    emission_profile = emission_profile_fixture()

    {:ok, quote} =
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
            amount: Decimal.new("10.0"),
            tax_rate: Decimal.new("15.0")
          }
        ]
      })
      |> Billing.Quotes.create_quote()

    quote
  end
end
