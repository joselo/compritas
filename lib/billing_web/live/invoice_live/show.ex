defmodule BillingWeb.InvoiceLive.Show do
  use BillingWeb, :live_view

  alias Billing.Invoices
  alias Billing.ElectronicInvoices
  alias Billing.ElectronicInvoice
  alias Billing.Invoices.ElectronicInvoice
  alias Billing.InvoicingWorker
  alias Phoenix.PubSub
  alias Billing.InvoiceHandler

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

          <.create_electronic_invoice_button electronic_invoice={@electronic_invoice} />
        </:actions>
      </.header>

      <.list>
        <:item title="Status">
          <.electronic_state electronic_invoice={@electronic_invoice} />
        </:item>
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
     |> assign(:electronic_invoice, ElectronicInvoices.get_electronic_invoice_by_invoice_id(id))}
  end

  @impl true
  def handle_event("create_electronic_invoice", _params, socket) do
    %{"invoice_id" => socket.assigns.invoice.id}
    |> InvoicingWorker.new()
    |> Oban.insert()

    {:noreply, put_flash(socket, :info, "Facturación en proceso")}
  end

  @impl true
  def handle_event("check_electronic_invoice", _params, socket) do
    InvoiceHandler.run_authorization_checker(socket.assigns.electronic_invoice.id)

    {:noreply, put_flash(socket, :info, "Verifición en proceso")}
  end

  @impl true
  def handle_info({:update_electronic_invoice, %{invoice_id: invoice_id}}, socket) do
    {:noreply,
     socket
     |> assign(
       :electronic_invoice,
       ElectronicInvoices.get_electronic_invoice_by_invoice_id(invoice_id)
     )}
  end

  @impl true
  def handle_info({:electronic_invoice_error, %{invoice_id: invoice_id, error: error}}, socket) do
    {:noreply,
     socket
     |> assign(
       :electronic_invoice,
       ElectronicInvoices.get_electronic_invoice_by_invoice_id(invoice_id)
     )
     |> put_flash(:error, "Error en la facturación: #{error}")}
  end

  attr :electronic_invoice, ElectronicInvoice, default: nil

  defp electronic_state(assigns) do
    assigns =
      assign_new(assigns, :state, fn ->
        if assigns.electronic_invoice do
          %{label: assigns.electronic_invoice.state, css_class: "badge-primary"}
        else
          %{label: "Not invoice yet", css_class: "badge-info"}
        end
      end)

    ~H"""
    <span class={["badge", @state.css_class]}>
      {@state.label}
    </span>
    """
  end

  attr :electronic_invoice, ElectronicInvoice, default: nil

  def create_electronic_invoice_button(
        %{electronic_invoice: %ElectronicInvoice{state: state}} = assigns
      )
      when state in [:created, :signed, :sent] do
    ~H"""
    <span>
      <span class="loading loading-spinner loading-md"></span>
    </span>
    """
  end

  def create_electronic_invoice_button(
        %{electronic_invoice: %ElectronicInvoice{state: state}} = assigns
      )
      when state in [:not_found_or_pending] do
    ~H"""
    <.button phx-click="check_electronic_invoice">
      <.icon name="hero-pencil-square" /> Verificar estado
    </.button>
    """
  end

  def create_electronic_invoice_button(
        %{electronic_invoice: %ElectronicInvoice{state: state}} = assigns
      )
      when state in [:authorized] do
    ~H"""
    Dropdown here
    """
  end

  # state is nil :back, :error or :unauthorized
  def create_electronic_invoice_button(assigns) do
    ~H"""
    <.button phx-click="create_electronic_invoice">
      <.icon name="hero-pencil-square" /> Crear Factura
    </.button>
    """
  end
end
