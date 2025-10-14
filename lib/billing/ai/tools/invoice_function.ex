defmodule Billing.Ai.Tools.InvoiceFunction do
  alias LangChain.Function
  alias Billing.Invoices

  def new!() do
    Function.new!(%{
      name: "invoices",
      display_text: "Facturas",
      description: "Obtiene la información de las facturas.",
      parameters_schema: %{},
      function: &execute/2
    })
  end

  def execute(_args, _context) do
    json_invoices = Jason.encode!(Invoices.list_invoices())

    {:ok, json_invoices}
  end
end
