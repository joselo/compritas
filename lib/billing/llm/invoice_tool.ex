defmodule Billing.LLM.InvoiceTool do
  alias LangChain.Function
  alias Billing.ElectronicInvoices

  def new!() do
    Function.new!(%{
      name: "quotes",
      display_text: "Facturas",
      description: "Obtiene la información de las facturas.",
      parameters_schema: %{},
      function: &execute/2
    })
  end

  def execute(_args, _context) do
    json_invoices = Jason.encode!(ElectronicInvoices.list_electronic_invoices())

    {:ok, json_invoices}
  end
end
