defmodule BillingWeb.QuoteLive.Form do
  use BillingWeb, :live_view

  alias Billing.Quotes
  alias Billing.Quotes.Quote
  alias Billing.Customers
  alias Billing.Customers.Customer
  alias Billing.Orders
  alias Billing.Quotes.QuoteItem

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage quote records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="quote-form" phx-change="validate" phx-submit="save" autocomplete="off">
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
        <.input
          field={@form[:payment_method]}
          type="select"
          options={@payment_methods}
          label="Payment Method"
        />

        <.inputs_for :let={f} field={@form[:items]}>
          <div class={[
            "flex space-x-2",
            Ecto.Changeset.get_field(f.source, :marked_for_deletion) && "hidden"
          ]}>
            <div class="grid grid-cols-3 gap-x-2 flex-1">
              <.input field={f[:description]} type="textarea" label={gettext("Description")} />
              <.input field={f[:amount]} type="text" label={gettext("Amount")} />
              <.input field={f[:tax_rate]} type="text" label={gettext("Tax Rate")} />
            </div>

            <div class="flex justify-end">
              <.button
                type="button"
                class="btn btn-neutral"
                phx-click="remove_item"
                phx-value-index={f.index}
              >
                {gettext("Remove")}
              </.button>

              <.input field={f[:marked_for_deletion]} type="checkbox" class="hidden" />
            </div>
          </div>
        </.inputs_for>

        <.button type="button" class="btn btn-secondary" phx-click="add_item">
          {gettext("Add Item")}
        </.button>

        <.error :for={msg <- Enum.map(@form[:items].errors, &translate_error(&1))}>
          {msg}
        </.error>

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
      items = Enum.map(order.items, &%{"description" => &1.name, "amount" => &1.price})
      due_date = DateTime.add(order.inserted_at, 15, :day)

      attrs = %{
        "customer_id" => customer.id,
        "description" => "Order #{order.id}",
        "issued_at" => order.inserted_at,
        "due_date" => due_date,
        "items" => items
      }

      socket
      |> assign_customers()
      |> assign_new_quote(attrs)
    else
      {:error, error} ->
        put_flash(socket, :error, inspect(error))
    end
  end

  defp apply_action(socket, :new, _params) do
    assign_new_quote(socket)
  end

  @impl true
  def handle_event("validate", %{"quote" => quote_params}, socket) do
    changeset = Quotes.change_quote(socket.assigns.quote, quote_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"quote" => quote_params}, socket) do
    save_quote(socket, socket.assigns.live_action, quote_params)
  end

  def handle_event("add_item", _params, socket) do
    items =
      Ecto.Changeset.get_field(socket.assigns.form.source, :items, socket.assigns.quote.items)

    items_updated = items ++ [Quotes.change_quote_item(%QuoteItem{})]
    changeset = Ecto.Changeset.put_assoc(socket.assigns.form.source, :items, items_updated)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("remove_item", %{"index" => index}, socket) do
    index = String.to_integer(index)

    items =
      socket.assigns.form.source
      |> Ecto.Changeset.get_field(:items)
      |> Enum.with_index()
      |> Enum.map(fn {item, item_index} ->
        if item_index == index do
          item
          |> Quotes.change_quote_item()
          |> Ecto.Changeset.put_change(:marked_for_deletion, true)
        else
          item
        end
      end)

    changeset = Ecto.Changeset.put_assoc(socket.assigns.form.source, :items, items)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  defp save_quote(socket, :edit, quote_params) do
    quote_params = filtered_items(quote_params)

    case Quotes.update_quote(socket.assigns.quote, quote_params) do
      {:ok, quote} ->
        save_quote_amounts(quote)

        {:noreply,
         socket
         |> put_flash(:info, "Invoice updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, quote))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_quote(socket, :new, quote_params) do
    quote_params = filtered_items(quote_params)

    case Quotes.create_quote(quote_params) do
      {:ok, quote} ->
        save_quote_amounts(quote)

        {:noreply,
         socket
         |> put_flash(:info, "Invoice created successfully")
         |> push_navigate(to: return_path("show", quote))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _invoice), do: ~p"/quotes"
  defp return_path("show", quote), do: ~p"/quotes/#{quote}"

  defp save_quote_amounts(quote) do
    Quotes.save_quote_amounts(quote)
  end

  defp find_or_create_customer(order) do
    order
    |> Map.take(Customer.list_required_fields())
    |> Customers.find_or_create_customer()
  end

  defp assign_new_quote(socket, params \\ %{}) do
    quote = %Quote{items: []}

    socket
    |> assign(:page_title, "New Invoice")
    |> assign(:quote, quote)
    |> assign(:form, to_form(Quotes.change_quote(quote, params)))
  end

  defp assign_customers(socket) do
    customers = Billing.Customers.list_customers() |> Enum.map(&{&1.full_name, &1.id})

    assign(socket, :customers, customers)
  end

  defp filtered_items(attrs) do
    items_map = attrs["items"] || %{}

    filtered_items =
      items_map
      |> Map.values()
      |> Enum.reject(fn item -> item["marked_for_deletion"] == "true" end)

    Map.put(attrs, "items", filtered_items)
  end
end
