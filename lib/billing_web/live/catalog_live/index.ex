defmodule BillingWeb.CatalogLive.Index do
  use BillingWeb, :live_view

  alias Billing.Products

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Product Catalog
      </.header>

      {inspect(@cart_uuid)}

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

    {:noreply, put_flash(socket, :info, "#{product.name} added to your cart")}
  end

  defp list_products() do
    Products.list_products()
  end
end
