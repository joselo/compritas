defmodule BillingWeb.InvoiceLive.Index do
  use BillingWeb, :live_view

  alias Billing.Invoices

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listado de Facturas
        <:actions>
          <.button variant="primary" navigate={~p"/invoices/new"}>
            <.icon name="hero-plus" /> New Invoice
          </.button>
        </:actions>
      </.header>

      <.table
        id="invoices"
        rows={@streams.invoices}
        row_click={fn {_id, invoice} -> JS.navigate(~p"/invoices/#{invoice}") end}
      >
        <:col :let={{_id, invoice}} label="Issued at">{invoice.issued_at}</:col>
        <:col :let={{_id, invoice}} label="Due date">{invoice.due_date}</:col>
        <:col :let={{_id, invoice}} label="Customer">{invoice.customer.full_name}</:col>
        <:col :let={{_id, invoice}} label="Amount">{invoice.amount}</:col>
        <:action :let={{_id, invoice}}>
          <div class="sr-only">
            <.link navigate={~p"/invoices/#{invoice}"}>Show</.link>
          </div>
          <.link navigate={~p"/invoices/#{invoice}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, invoice}}>
          <.link
            phx-click={JS.push("delete", value: %{id: invoice.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listado de Facturas")
     |> stream(:invoices, Invoices.list_invoices())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    invoice = Invoices.get_invoice!(id)
    {:ok, _} = Invoices.delete_invoice(invoice)

    {:noreply, stream_delete(socket, :invoices, invoice)}
  end
end
