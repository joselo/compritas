defmodule BillingWeb.CatalogLive.Index do
  use BillingWeb, :live_view

  alias Billing.Products
  alias Billing.Carts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.public flash={@flash} current_scope={@current_scope}>
      <.header>
        Product Catalog
        <:actions>
          <.link :if={@cart_size > 0} navigate={~p"/cart"} class="btn btn-primary">
            <.icon name="hero-shopping-cart" /> {@cart_size}
          </.link>
        </:actions>
      </.header>

      <.table
        id="products"
        rows={@streams.products}
        row_click={fn {_id, product} -> JS.navigate(~p"/item/#{product}") end}
      >
        <:col :let={{_id, product}} label="Name">{product.name}</:col>
        <:col :let={{_id, product}} label="Price">{product.price}</:col>
        <:action :let={{_id, product}}>
          <.button phx-click={JS.push("add_to_cart", value: %{id: product.id})}>
            Add to Cart
          </.button>
        </:action>
      </.table>
    </Layouts.public>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Products")
     |> assign(:cart_size, cart_size(socket.assigns.cart_uuid))
     |> stream(:products, list_products())}
  end

  @impl true
  def handle_event("add_to_cart", %{"id" => id}, socket) do
    product = Products.get_product!(id)

    attrs = %{
      cart_uuid: socket.assigns.cart_uuid,
      product_name: product.name,
      product_price: product.price
    }

    case Carts.create_cart(attrs) do
      {:ok, _cart} ->
        {:noreply,
         socket
         |> assign(:cart_size, cart_size(socket.assigns.cart_uuid))
         |> put_flash(:info, "#{product.name} added to your cart")}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, inspect(changeset))}
    end
  end

  defp list_products() do
    Products.list_products()
  end

  defp cart_size(cart_uuid) do
    Enum.count(Carts.list_carts(cart_uuid))
  end
end
