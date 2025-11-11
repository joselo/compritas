defmodule Billing.CompaniesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Billing.Companies` context.
  """

  @doc """
  Generate a company.
  """
  def company_fixture(scope, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        address: "some address",
        identification_number: "some identification_number",
        name: "some name"
      })

    {:ok, company} = Billing.Companies.create_company(scope, attrs)

    company
  end
end
