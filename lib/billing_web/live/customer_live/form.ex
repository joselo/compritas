defmodule BillingWeb.CustomerLive.Form do
  use BillingWeb, :live_view

  alias Billing.Customers
  alias Billing.Customers.Customer

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
      </.header>

      <.form for={@form} id="customer-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:full_name]} type="text" label={gettext("Full name")} />
        <.input field={@form[:email]} type="text" label={gettext("Email")} />
        <.input
          field={@form[:identification_type]}
          type="select"
          label={gettext("Identification Type")}
          options={@identification_types}
        />
        <.input
          field={@form[:identification_number]}
          type="text"
          label={gettext("Identification Number")}
        />
        <.input field={@form[:address]} type="text" label={gettext("Address")} />
        <.input field={@form[:phone_number]} type="text" label={gettext("Phone Number")} />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">{gettext("Save Customer")}</.button>
          <.button navigate={return_path(@return_to, @customer)}>{gettext("Cancel")}</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    identification_types = [{"Cedula", :cedula}, {"Ruc", :ruc}]

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:identification_types, identification_types)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    customer = Customers.get_customer!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Customer")
    |> assign(:customer, customer)
    |> assign(:form, to_form(Customers.change_customer(socket.assigns.current_scope, customer)))
  end

  defp apply_action(socket, :new, _params) do
    customer = %Customer{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Customer")
    |> assign(:customer, customer)
    |> assign(:form, to_form(Customers.change_customer(socket.assigns.current_scope, customer)))
  end

  @impl true
  def handle_event("validate", %{"customer" => customer_params}, socket) do
    changeset =
      Customers.change_customer(
        socket.assigns.current_scope,
        socket.assigns.customer,
        customer_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"customer" => customer_params}, socket) do
    save_customer(socket, socket.assigns.live_action, customer_params)
  end

  defp save_customer(socket, :edit, customer_params) do
    case Customers.update_customer(
           socket.assigns.current_scope,
           socket.assigns.customer,
           customer_params
         ) do
      {:ok, customer} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Customer updated successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, customer))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_customer(socket, :new, customer_params) do
    case Customers.create_customer(socket.assigns.current_scope, customer_params) do
      {:ok, customer} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Customer created successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, customer))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _customer), do: ~p"/customers"
  defp return_path("show", customer), do: ~p"/customers/#{customer}"
end
