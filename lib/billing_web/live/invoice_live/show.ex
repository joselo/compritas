defmodule BillingWeb.InvoiceLive.Show do
  use BillingWeb, :live_view

  alias Billing.Invoices

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Invoice {@invoice.id}
        <:subtitle>This is a invoice record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/invoices"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/invoices/#{@invoice}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit invoice
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Issued at">{@invoice.issued_at}</:item>
        <:item title="Customer">{@invoice.customer.full_name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Invoice")
     |> assign(:invoice, Invoices.get_invoice!(id))}
  end
end
