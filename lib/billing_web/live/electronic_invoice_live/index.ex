defmodule BillingWeb.ElectronicInvoiceLive.Index do
  use BillingWeb, :live_view

  alias Billing.ElectronicInvoices
  alias BillingWeb.ElectronicInvoiceComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Electronic Quotes
      </.header>

      <.table
        id="electronic_invoices"
        rows={@streams.electronic_invoices}
        row_click={
          fn {_id, electronic_invoice} ->
            JS.navigate(~p"/electronic_invoices/#{electronic_invoice}")
          end
        }
      >
        <:col :let={{_id, electronic_invoice}} label="State">
          <ElectronicInvoiceComponents.state electronic_invoice={electronic_invoice} />
        </:col>
        <:col :let={{_id, electronic_invoice}} label="Date">{electronic_invoice.inserted_at}</:col>
        <:col :let={{_id, electronic_invoice}} label="Amount">{electronic_invoice.amount}</:col>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Electronic Quotes")
     |> stream(:electronic_invoices, list_electronic_invoices())}
  end

  defp list_electronic_invoices() do
    ElectronicInvoices.list_electronic_invoices()
  end
end
