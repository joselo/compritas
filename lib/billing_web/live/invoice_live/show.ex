defmodule BillingWeb.InvoiceLive.Show do
  use BillingWeb, :live_view

  alias Billing.Invoices
  alias Billing.ElectronicInvoices
  alias Billing.ElectronicInvoice
  alias Billing.Invoices.ElectronicInvoice
  alias Billing.InvoicingWorker
  alias Phoenix.PubSub
  alias Billing.InvoiceHandler
  alias Billing.ElectronicInvoiceErrors

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

          <.create_electronic_invoice_button electronic_invoice={@electronic_invoice} />
        </:actions>
      </.header>

      <.electronic_invoice_errors errors={@electronic_invoice_errors} />

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
     |> assign_electronic_invoice()}
  end

  @impl true
  def handle_event("create_electronic_invoice", _params, socket) do
    %{"invoice_id" => socket.assigns.invoice.id}
    |> InvoicingWorker.new()
    |> Oban.insert()

    {:noreply, assign(socket, :electronic_invoice, %ElectronicInvoice{state: :created})}
  end

  @impl true
  def handle_event("check_electronic_invoice", _params, socket) do
    InvoiceHandler.run_authorization_checker(socket.assigns.electronic_invoice.id)

    {:noreply, put_flash(socket, :info, "Verifición en proceso")}
  end

  @impl true
  def handle_info({:update_electronic_invoice, %{invoice_id: _invoice_id}}, socket) do
    {:noreply, assign_electronic_invoice(socket)}
  end

  @impl true
  def handle_info({:electronic_invoice_error, %{invoice_id: _invoice_id, error: error}}, socket) do
    {:noreply,
     socket
     |> assign_electronic_invoice()
     |> put_flash(:error, "Error en la facturación: #{error}")}
  end

  attr :electronic_invoice, ElectronicInvoice, default: nil

  defp electronic_state(assigns) do
    assigns =
      assign_new(assigns, :state, fn ->
        if assigns.electronic_invoice do
          %{
            label: ElectronicInvoice.label_status(assigns.electronic_invoice.state),
            css_class: "badge-primary"
          }
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

  defp create_electronic_invoice_button(
         %{electronic_invoice: %ElectronicInvoice{state: state}} = assigns
       )
       when state in [:created, :signed, :sent] do
    ~H"""
    <.button disabled>
      <span class="loading loading-spinner"></span>Creando Factura Electrónica
    </.button>
    """
  end

  defp create_electronic_invoice_button(
         %{electronic_invoice: %ElectronicInvoice{state: state}} = assigns
       )
       when state in [:not_found_or_pending] do
    ~H"""
    <.button phx-click="check_electronic_invoice">
      <.icon name="hero-bolt-slash" /> Verificar Factura Electrónica
    </.button>
    """
  end

  defp create_electronic_invoice_button(
         %{electronic_invoice: %ElectronicInvoice{state: state}} = assigns
       )
       when state in [:authorized] do
    ~H"""
    <.link href={~p"/electronic_invoice/#{@electronic_invoice.id}/pdf"} class="btn btn-ghost">
      <.icon name="hero-arrow-down-tray" /> PDF
    </.link>

    <.link href={~p"/electronic_invoice/#{@electronic_invoice.id}/xml"} class="btn btn-ghost">
      <.icon name="hero-arrow-down-tray" /> XML
    </.link>
    """
  end

  defp create_electronic_invoice_button(assigns) do
    ~H"""
    <.button
      phx-click="create_electronic_invoice"
      data-confirm="¿Estás seguro de crear una factura electrónica?"
    >
      <.icon name="hero-bolt" /> Crear Factura Electrónica
    </.button>
    """
  end

  attr :errors, :list, default: []

  defp electronic_invoice_errors(%{errors: []} = assigns) do
    ~H"""
    """
  end

  defp electronic_invoice_errors(assigns) do
    ~H"""
    <div role="alert" class="alert alert-error">
      <.icon name="hero-x-circle" />

      <ul>
        <li :for={{key, value} <- @errors}>
          {key}: {value}
        </li>
      </ul>
    </div>
    """
  end

  defp assign_electronic_invoice(socket) do
    electronic_invoice =
      ElectronicInvoices.get_electronic_invoice_by_invoice_id(socket.assigns.invoice.id)

    electronic_invoice_errors = ElectronicInvoiceErrors.list_errors(electronic_invoice)

    socket
    |> assign(:electronic_invoice, electronic_invoice)
    |> assign(:electronic_invoice_errors, electronic_invoice_errors)
  end
end
