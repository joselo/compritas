defmodule BillingWeb.CartLive.Index do
  use BillingWeb, :live_view

  alias Billing.Carts
  alias Billing.Orders
  alias Billing.Orders.Order

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.public flash={@flash} current_scope={@current_scope} return_to={~p"/"}>
      <.header>
        {gettext("Your Cart")}
      </.header>

      <.table
        id="carts"
        rows={@streams.carts}
      >
        <:col :let={{_id, cart}} label={gettext("Product")}>{cart.product_name}</:col>
        <:col :let={{_id, cart}} label={gettext("Price")}>{cart.product_price}</:col>
        <:action :let={{id, cart}}>
          <.button
            phx-click={JS.push("delete", value: %{id: cart.id}) |> hide("##{id}")}
            data-confirm={gettext("Are you sure?")}
            class="btn btn-error btn-soft"
          >
            {gettext("Remove")}
          </.button>
        </:action>
      </.table>

      <.form for={@form} id="order-form" phx-change="validate" phx-submit="save" autocomplete="off">
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
          <.button phx-disable-with="Saving..." variant="primary">{gettext("Place order")}</.button>
        </footer>
      </.form>
    </Layouts.public>
    """
  end

  on_mount {__MODULE__, :default}

  def on_mount(:default, _params, _session, socket) do
    if Enum.empty?(list_carts(socket.assigns.cart_uuid)) do
      {:halt, redirect(socket, to: ~p"/")}
    else
      {:cont, socket}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    order = %Order{user_id: socket.assigns.user_scope.user.id}
    identification_types = [{"Cedula", :cedula}, {"Ruc", :ruc}]

    {:ok,
     socket
     |> assign(:page_title, gettext("Your Cart"))
     |> assign(:order, order)
     |> assign(:form, to_form(Orders.change_order(socket.assigns.user_scope, order)))
     |> assign(:identification_types, identification_types)
     |> stream(:carts, list_carts(socket.assigns.cart_uuid))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cart = Carts.get_cart!(id)
    {:ok, _} = Carts.delete_cart(cart)

    {:noreply, stream_delete(socket, :carts, cart)}
  end

  @impl true
  def handle_event("validate", %{"order" => order_params}, socket) do
    changeset = Orders.change_order(socket.assigns.user_scope, socket.assigns.order, order_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"order" => order_params}, socket) do
    carts = list_carts(socket.assigns.cart_uuid)

    if Enum.empty?(carts) do
      {:noreply, redirect(socket, to: ~p"/")}
    else
      save_order(carts, order_params, socket)
    end
  end

  defp save_order(carts, order_params, socket) do
    items =
      Enum.map(carts, fn cart ->
        %{name: cart.product_name, price: cart.product_price}
      end)

    params = Map.put(order_params, "items", items)

    case Orders.create_order(socket.assigns.user_scope, params) do
      {:ok, order} ->
        Carts.clean_cart(socket.assigns.cart_uuid)
        Orders.save_order_amounts(order)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Order created successfully"))
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp list_carts(cart_uuid) do
    Carts.list_carts(cart_uuid)
  end
end
