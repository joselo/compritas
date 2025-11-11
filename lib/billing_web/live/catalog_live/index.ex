defmodule BillingWeb.CatalogLive.Index do
  use BillingWeb, :live_view

  alias Billing.Products
  alias Billing.Carts
  alias BillingWeb.ProductComponents
  alias BillingWeb.SharedComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.public flash={@flash} current_scope={@current_scope}>
      <SharedComponents.cart_status cart_size={@cart_size} />

      <.header>
        {gettext("Welcome to our product catalog.")}
      </.header>

      <ul id="products" class="list" phx-update="stream">
        <li :for={{dom_id, product} <- @streams.products} class="list-row" id={dom_id}>
          <.link navigate={~p"/item/#{product}"}>
            <ProductComponents.files files={product.files} />
          </.link>

          <div class="space-y-4">
            <.link navigate={~p"/item/#{product}"} class="block text-normal link link-hover">
              {product.name}
            </.link>

            <div class="uppercase font-semibold text-lg">{product.price}</div>

            <.button phx-click={JS.push("add_to_cart", value: %{id: product.id})} variant="primary">
              <.icon name="hero-plus" /> {gettext("Add to Cart")}
            </.button>
          </div>
        </li>
      </ul>
    </Layouts.public>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Listing Products"))
     |> assign(:cart_size, cart_size(socket.assigns.cart_uuid))
     |> stream(:products, list_products(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("add_to_cart", %{"id" => id}, socket) do
    product = Products.get_product!(socket.assigns.current_scope, id)

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
         |> put_flash(
           :info,
           gettext("%{product_name} added to your cart", product_name: product.name)
         )}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, inspect(changeset))}
    end
  end

  defp list_products(current_scope) do
    Products.list_products(current_scope)
  end

  defp cart_size(cart_uuid) do
    Enum.count(Carts.list_carts(cart_uuid))
  end
end
