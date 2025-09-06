defmodule BillingWeb.InvoiceLive.Show do
  use BillingWeb, :live_view

  alias Billing.Invoices
  alias Billing.Invoicing
  alias Billing.TaxiDriver

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
          <.button phx-click="build_xml">
            <.icon name="hero-pencil-square" /> Build XML
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

  @impl true
  def handle_event("build_xml", _params, socket) do
    invoice_params = Invoicing.build_request_params(socket.assigns.invoice)

    case TaxiDriver.build_invoice_xml(invoice_params) do
      {:ok, xml} ->
        File.write("/home/joselo/Documents/invoice-#{socket.assigns.invoice.id}.xml", xml)

        {:noreply, put_flash(socket, :info, "Xml success!!")}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, "Xml error: #{inspect(error)}")}
    end
  end
end
