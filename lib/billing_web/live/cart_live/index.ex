defmodule BillingWeb.CartLive.Index do
  use BillingWeb, :live_view

  alias Billing.Carts

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
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Carts")
     |> stream(:carts, list_carts())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cart = Carts.get_cart!(id)
    {:ok, _} = Carts.delete_cart(cart)

    {:noreply, stream_delete(socket, :carts, cart)}
  end

  defp list_carts() do
    Carts.list_carts()
  end
end
