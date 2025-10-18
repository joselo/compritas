defmodule BillingWeb.CartLive.Index do
  use BillingWeb, :live_view

  alias Billing.Carts
  alias Billing.Orders
  alias Billing.Orders.Order

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Your Cart
      </.header>

      <.table
        id="carts"
        rows={@streams.carts}
      >
        <:col :let={{_id, cart}} label="Name">{cart.product_name}</:col>
        <:col :let={{_id, cart}} label="Price">{cart.product_price}</:col>
        <:action :let={{id, cart}}>
          <.button
            phx-click={JS.push("delete", value: %{id: cart.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.button>
        </:action>
      </.table>

      <.form for={@form} id="order-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:full_name]} type="text" label="Your Name" />
        <.input field={@form[:phone_number]} type="text" label="Your Phone Number" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Create order</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    order = %Order{}

    {:ok,
     socket
     |> assign(:page_title, "Your Cart")
     |> assign(:order, order)
     |> assign(:form, to_form(Orders.change_order(order)))
     |> stream(:carts, list_carts())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cart = Carts.get_cart!(id)
    {:ok, _} = Carts.delete_cart(cart)

    {:noreply, stream_delete(socket, :carts, cart)}
  end

  @impl true
  def handle_event("validate", %{"order" => order_params}, socket) do
    changeset = Orders.change_order(socket.assigns.order, order_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"order" => order_params}, socket) do
    params = Map.put(order_params, "cart_uuid", socket.assigns.cart_uuid)

    case Orders.create_order(params) do
      {:ok, _order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Order created successfully")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp list_carts() do
    Carts.list_carts()
  end
end
