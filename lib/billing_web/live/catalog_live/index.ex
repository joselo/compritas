defmodule BillingWeb.CatalogLive.Index do
  use BillingWeb, :live_view

  alias Billing.Products
  alias Billing.Carts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Product Catalog
      </.header>

      <.table
        id="products"
        rows={@streams.products}
      >
        <:col :let={{_id, product}} label="Name">{product.name}</:col>
        <:col :let={{_id, product}} label="Price">{product.price}</:col>
        <:action :let={{_id, product}}>
          <.button phx-click={JS.push("add_to_cart", value: %{id: product.id})}>
            Add to Cart
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
     |> assign(:page_title, "Listing Products")
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
        {:noreply, put_flash(socket, :info, "#{product.name} added to your cart")}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, inspect(changeset))}
    end
  end

  defp list_products() do
    Products.list_products()
  end
end
