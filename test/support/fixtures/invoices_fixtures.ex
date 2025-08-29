defmodule Billing.InvoicesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Billing.Invoices` context.
  """

  @doc """
  Generate a invoice.
  """
  def invoice_fixture(attrs \\ %{}) do
    {:ok, invoice} =
      attrs
      |> Enum.into(%{
        issued_at: ~D[2025-08-28]
      })
      |> Billing.Invoices.create_invoice()

    invoice
  end
end
