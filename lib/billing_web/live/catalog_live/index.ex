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

      <ul id="products" class="list bg-base-100 rounded-box shadow-md" phx-update="stream">
        <li :for={{dom_id, product} <- @streams.products} class="list-row" id={dom_id}>
          <div>
            <img
              class="size-50 rounded-box"
              src="https://img.daisyui.com/images/profile/demo/1@94.webp"
            />
          </div>
          <div>
            <div>{product.name}</div>
            <div class="uppercase font-semibold opacity-60">{product.price}</div>
          </div>
          <.button phx-click={JS.push("add_to_cart", value: %{id: product.id})}>
            Add to Cart
          </.button>
        </li>
      </ul>
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
