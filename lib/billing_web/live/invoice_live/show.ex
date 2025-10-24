defmodule BillingWeb.InvoiceLive.Show do
  use BillingWeb, :live_view

  alias Billing.Invoices
  # alias Billing.InvoicingWorker
  alias Phoenix.PubSub
  alias Billing.InvoiceHandler
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
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

          <.button variant="primary" phx-click="create_electronic_invoice">
            <.icon name="hero-bolt-slash" /> Create electronic invoice
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
    PubSub.subscribe(Billing.PubSub, "invoice:#{id}")

    {:ok,
     socket
     |> assign(:page_title, "Show Invoice")
     |> assign(:invoice, Invoices.get_invoice!(id))
     |> assign(:electronic_invoice, nil)}
  end

  @impl true
  def handle_event("create_electronic_invoice", _params, socket) do
    # %{"invoice_id" => socket.assigns.invoice.id}
    # |> InvoicingWorker.new()
    # |> Oban.insert()
    #
    # {:noreply, assign(socket, :electronic_invoice, %ElectronicInvoice{state: :created})}
    invoice_id = socket.assigns.invoice.id

    {:noreply,
     socket
     |> assign(:electronic_invoice, AsyncResult.loading())
     |> start_async(:create_electronic_invoice, fn ->
       InvoiceHandler.build_electronic_invoice(invoice_id)
     end)}
  end

  @impl true
  def handle_async(:create_electronic_invoice, {:ok, electronic_invoice}, socket) do
    Process.sleep(5000)

    {:noreply,
     socket
     |> assign(:electronic_invoice, AsyncResult.ok(electronic_invoice))
     |> put_flash(:info, "Electronic invoice created")}
  end

  def handle_async(:create_electronic_invoice, {:error, error}, socket) do
    electronic_invoice = socket.assigns.electronic_invoice

    {:noreply,
     socket
     |> assign(:electronic_invoice, AsyncResult.failed(electronic_invoice, {:error, error}))
     |> put_flash(:error, "Error: #{inspect(error)}")}
  end

  def handle_async(:create_electronic_invoice, {:exit, reason}, socket) do
    electronic_invoice = socket.assigns.electronic_invoice

    {:noreply,
     socket
     |> assign(:electronic_invoice, AsyncResult.failed(electronic_invoice, {:exit, reason}))
     |> put_flash(:error, "Error: #{inspect(reason)}")}
  end
end
