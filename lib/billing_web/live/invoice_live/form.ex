defmodule BillingWeb.InvoiceLive.Form do
  use BillingWeb, :live_view

  alias Billing.Invoices
  alias Billing.Invoices.Invoice

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage invoice records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="invoice-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:customer_id]} type="select" options={@customers} label="Customer" />
        <.input field={@form[:issued_at]} type="date" label="Issued at" />
        <.input field={@form[:due_date]} type="date" label="Due Date" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:amount]} type="number" label="Amount" />
        <.input field={@form[:tax_rate]} type="number" label="Tax Rate" />
        <.input
          field={@form[:payment_method]}
          type="select"
          options={@payment_methods}
          label="Payment Method"
        />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Invoice</.button>
          <.button navigate={return_path(@return_to, @invoice)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    customers = Billing.Customers.list_customers() |> Enum.map(&{&1.full_name, &1.id})

    payment_methods = [
      {"Credit Card", :credit_card},
      {"Cash", :cash},
      {"Bank Transfer", :bank_transfer}
    ]

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:customers, customers)
     |> assign(:payment_methods, payment_methods)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    invoice = Invoices.get_invoice!(id)

    socket
    |> assign(:page_title, "Edit Invoice")
    |> assign(:invoice, invoice)
    |> assign(:form, to_form(Invoices.change_invoice(invoice)))
  end

  defp apply_action(socket, :new, _params) do
    invoice = %Invoice{}

    socket
    |> assign(:page_title, "New Invoice")
    |> assign(:invoice, invoice)
    |> assign(:form, to_form(Invoices.change_invoice(invoice)))
  end

  @impl true
  def handle_event("validate", %{"invoice" => invoice_params}, socket) do
    changeset = Invoices.change_invoice(socket.assigns.invoice, invoice_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"invoice" => invoice_params}, socket) do
    save_invoice(socket, socket.assigns.live_action, invoice_params)
  end

  defp save_invoice(socket, :edit, invoice_params) do
    case Invoices.update_invoice(socket.assigns.invoice, invoice_params) do
      {:ok, invoice} ->
        save_invoice_taxes(invoice)

        {:noreply,
         socket
         |> put_flash(:info, "Invoice updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, invoice))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_invoice(socket, :new, invoice_params) do
    case Invoices.create_invoice(invoice_params) do
      {:ok, invoice} ->
        save_invoice_taxes(invoice)

        {:noreply,
         socket
         |> put_flash(:info, "Invoice created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, invoice))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _invoice), do: ~p"/invoices"
  defp return_path("show", invoice), do: ~p"/invoices/#{invoice}"

  defp save_invoice_taxes(invoice) do
    amount_with_tax = Invoices.calculate_amount_with_tax(invoice)
    Invoices.save_taxes(invoice, amount_with_tax)
  end
end
