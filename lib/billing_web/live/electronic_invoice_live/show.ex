defmodule BillingWeb.ElectronicInvoiceLive.Show do
  use BillingWeb, :live_view

  alias Billing.ElectronicInvoices
  alias Billing.ElectronicInvoice
  alias Billing.Quotes.ElectronicInvoice
  alias Phoenix.PubSub
  alias Billing.InvoiceHandler
  alias Billing.ElectronicInvoiceErrors
  alias Phoenix.LiveView.AsyncResult
  alias BillingWeb.ElectronicInvoiceComponents
  alias Billing.Quotes

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      return_to={~p"/electronic_invoices"}
      settings={@settings}
    >
      <.header>
        {gettext("Electronic Invoice %{electronic_invoice_id}",
          electronic_invoice_id: @electronic_invoice.id
        )}
        <:subtitle>{@electronic_invoice.inserted_at}</:subtitle>
        <:actions>
          <.send_button :if={allow_send(@electronic_invoice.state)} send_result={@send_result} />
          <.auth_button
            :if={allow_verify_authorization(@electronic_invoice.state)}
            auth_result={@auth_result}
          />
        </:actions>
      </.header>

      <.electronic_invoice_errors errors={@electronic_invoice_errors} />

      <.list>
        <:item title="Status">
          <ElectronicInvoiceComponents.state electronic_invoice={@electronic_invoice} />
        </:item>
        <:item title={gettext("Date")}>{@electronic_invoice.inserted_at}</:item>
        <:item title={gettext("Amount")}>{@electronic_invoice.amount}</:item>
        <:item title={gettext("Access Key")}>{@electronic_invoice.access_key}</:item>
        <:item title={gettext("Quote Id")}>
          <.link navigate={~p"/quotes/#{@quote.id}"} class="link">
            {@quote.id}
          </.link>
        </:item>
        <:item
          :if={ElectronicInvoice.authorized?(@electronic_invoice.state)}
          title={gettext("Documents")}
        >
          <.link href={~p"/electronic_invoice/#{@electronic_invoice.id}/xml"} class="btn btn-ghost">
            <.icon name="hero-arrow-down-tray" /> XML
          </.link>

          <.link href={~p"/electronic_invoice/#{@electronic_invoice.id}/pdf"} class="btn btn-ghost">
            <.icon name="hero-arrow-down-tray" /> PDF
          </.link>
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    PubSub.subscribe(Billing.PubSub, "electronic_invoice:#{id}")

    socket = assign_electronic_invoice(socket, id)

    {:ok,
     socket
     |> assign(
       :page_title,
       gettext("Electronic Invoice %{electronic_invoice_id}", electronic_invoice_id: id)
     )
     |> assign(:send_result, %AsyncResult{})
     |> assign(:auth_result, %AsyncResult{})
     |> assign_invoice()}
  end

  @impl true
  def handle_event("send_electronic_invoice", _params, socket) do
    electronic_invoice_id = socket.assigns.electronic_invoice.id
    current_scope = socket.assigns.current_scope

    {:noreply,
     socket
     |> assign(:send_result, AsyncResult.loading())
     |> start_async(:send_electronic_invoice, fn ->
       InvoiceHandler.send_electronic_invoice(current_scope, electronic_invoice_id)
     end)}
  end

  @impl true
  def handle_event("auth_electronic_invoice", _params, socket) do
    electronic_invoice_id = socket.assigns.electronic_invoice.id
    current_scope = socket.assigns.current_scope

    {:noreply,
     socket
     |> assign(:auth_result, AsyncResult.loading())
     |> start_async(:auth_electronic_invoice, fn ->
       InvoiceHandler.auth_electronic_invoice(current_scope, electronic_invoice_id)
     end)}
  end

  @impl true
  def handle_async(:send_electronic_invoice, {:ok, {:ok, electronic_invoice}}, socket) do
    {:noreply,
     socket
     |> assign(:send_result, AsyncResult.ok(%AsyncResult{}))
     |> assign_electronic_invoice(electronic_invoice.id)
     |> put_flash(:info, "Electronic sent")}
  end

  def handle_async(:send_electronic_invoice, {:ok, {:error, error}}, socket) do
    {:noreply,
     socket
     |> assign(:send_result, AsyncResult.failed(%AsyncResult{}, {:error, error}))
     |> put_flash(:error, "Error: #{inspect(error)}")}
  end

  def handle_async(:send_electronic_invoice, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:send_result, AsyncResult.failed(%AsyncResult{}, {:exit, reason}))
     |> put_flash(:error, "Error: #{inspect(reason)}")}
  end

  @impl true
  def handle_async(:auth_electronic_invoice, {:ok, {:ok, electronic_invoice}}, socket) do
    {:noreply,
     socket
     |> assign(:auth_result, AsyncResult.ok(%AsyncResult{}))
     |> assign_electronic_invoice(electronic_invoice.id)
     |> put_flash(:info, "Electronic auth")}
  end

  def handle_async(:auth_electronic_invoice, {:ok, {:error, error}}, socket) do
    {:noreply,
     socket
     |> assign(:auth_result, AsyncResult.failed(%AsyncResult{}, {:error, error}))
     |> put_flash(:error, "Error: #{inspect(error)}")}
  end

  def handle_async(:auth_electronic_invoice, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:auth_result, AsyncResult.failed(%AsyncResult{}, {:exit, reason}))
     |> put_flash(:error, "Error: #{inspect(reason)}")}
  end

  @impl true
  def handle_info(
        {:electronic_invoice_updated, %{electronic_invoice_id: electronic_invoice_id}},
        socket
      ) do
    {:noreply, assign_electronic_invoice(socket, electronic_invoice_id)}
  end

  @impl true
  def handle_info(
        {:electronic_invoice_error,
         %{electronic_invoice_id: electronic_invoice_id, error: error}},
        socket
      ) do
    {:noreply,
     socket
     |> assign_electronic_invoice(electronic_invoice_id)
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
          %{label: "Not quote yet", css_class: "badge-info"}
        end
      end)

    ~H"""
    <span class={["badge", @state.css_class]}>
      {@state.label}
    </span>
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

  defp assign_electronic_invoice(socket, electronic_invoice_id) do
    electronic_invoice =
      ElectronicInvoices.get_electronic_invoice!(
        socket.assigns.current_scope,
        electronic_invoice_id
      )

    electronic_invoice_errors =
      ElectronicInvoiceErrors.list_errors(socket.assigns.current_scope, electronic_invoice)

    socket
    |> assign(:electronic_invoice, electronic_invoice)
    |> assign(:electronic_invoice_errors, electronic_invoice_errors)
  end

  defp assign_invoice(socket) do
    assign(
      socket,
      :quote,
      Quotes.get_quote!(socket.assigns.current_scope, socket.assigns.electronic_invoice.quote_id)
    )
  end

  attr :send_result, AsyncResult, required: true

  defp send_button(assigns) do
    ~H"""
    <.button variant="primary" phx-click="send_electronic_invoice" disabled={@send_result.loading}>
      <span :if={@send_result.loading} class="loading loading-spinner loading-md"></span>
      <.icon :if={!@send_result.loading} name="hero-paper-airplane" /> Send electronic quote
    </.button>
    """
  end

  attr :auth_result, AsyncResult, required: true

  defp auth_button(assigns) do
    ~H"""
    <.button variant="primary" phx-click="auth_electronic_invoice" disabled={@auth_result.loading}>
      <span :if={@auth_result.loading} class="loading loading-spinner loading-md"></span>
      <.icon :if={!@auth_result.loading} name="hero-check-badge" /> Auth electronic quote
    </.button>
    """
  end

  defp allow_verify_authorization(state) do
    ElectronicInvoice.allow_verify_authorization(state)
  end

  defp allow_send(state) do
    ElectronicInvoice.allow_send(state)
  end
end
