defmodule BillingWeb.QuoteLive.Form do
  use BillingWeb, :live_view

  alias Billing.Quotes
  alias Billing.Quotes.Quote
  alias Billing.Customers
  alias Billing.Customers.Customer
  alias Billing.Orders

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage quote records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="quote-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:customer_id]} type="select" options={@customers} label="Customer" />
        <.input
          field={@form[:emission_profile_id]}
          type="select"
          options={@emission_profiles}
          label="Emission Profile"
        />
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
          <.button navigate={return_path(@return_to, @quote)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    emission_profiles =
      Billing.EmissionProfiles.list_emission_profiles() |> Enum.map(&{&1.name, &1.id})

    payment_methods = [
      {"Credit Card", :credit_card},
      {"Cash", :cash},
      {"Bank Transfer", :bank_transfer}
    ]

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:emission_profiles, emission_profiles)
     |> assign(:payment_methods, payment_methods)
     |> assign_customers()
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    quote = Quotes.get_quote!(id)

    socket
    |> assign(:page_title, "Edit Invoice")
    |> assign(:quote, quote)
    |> assign(:form, to_form(Quotes.change_quote(quote)))
  end

  defp apply_action(socket, :new, %{"order_id" => order_id}) do
    order = Orders.get_order!(order_id)

    with {:ok, customer} <- find_or_create_customer(order) do
      acc = %{"description" => "", "amount" => Decimal.new("0.0")}

      order_attrs =
        Enum.reduce(order.items, acc, fn item, acc ->
          price = Decimal.to_string(item.price)

          acc
          |> Map.replace(
            "description",
            Enum.join([acc["description"], "#{item.name} (#{price})"], " | ")
          )
          |> Map.replace("amount", Decimal.add(acc["amount"], item.price))
        end)

      attrs = Map.merge(order_attrs, %{"customer_id" => customer.id})

      socket
      |> assign_customers()
      |> assign_new_invoice(attrs)
    else
      {:error, error} ->
        put_flash(socket, :error, inspect(error))
    end
  end

  defp apply_action(socket, :new, _params) do
    assign_new_invoice(socket)
  end

  @impl true
  def handle_event("validate", %{"quote" => invoice_params}, socket) do
    changeset = Quotes.change_quote(socket.assigns.quote, invoice_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"quote" => invoice_params}, socket) do
    save_invoice(socket, socket.assigns.live_action, invoice_params)
  end

  defp save_invoice(socket, :edit, invoice_params) do
    case Quotes.update_quote(socket.assigns.quote, invoice_params) do
      {:ok, quote} ->
        save_invoice_taxes(quote)

        {:noreply,
         socket
         |> put_flash(:info, "Invoice updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, quote))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_invoice(socket, :new, invoice_params) do
    case Quotes.create_quote(invoice_params) do
      {:ok, quote} ->
        save_invoice_taxes(quote)

        {:noreply,
         socket
         |> put_flash(:info, "Invoice created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, quote))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _invoice), do: ~p"/quotes"
  defp return_path("show", quote), do: ~p"/quotes/#{quote}"

  defp save_invoice_taxes(quote) do
    amount_without_tax = Quotes.calculate_amount_without_tax(quote)
    Quotes.save_taxes(quote, amount_without_tax)
  end

  defp find_or_create_customer(order) do
    order
    |> Map.take(Customer.list_required_fields())
    |> Customers.find_or_create_customer()
  end

  defp assign_new_invoice(socket, params \\ %{}) do
    quote = %Quote{}

    socket
    |> assign(:page_title, "New Invoice")
    |> assign(:quote, quote)
    |> assign(:form, to_form(Quotes.change_quote(quote, params)))
  end

  defp assign_customers(socket) do
    customers = Billing.Customers.list_customers() |> Enum.map(&{&1.full_name, &1.id})

    assign(socket, :customers, customers)
  end
end
