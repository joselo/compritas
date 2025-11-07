defmodule BillingWeb.CatalogLive.Show do
  use BillingWeb, :live_view

  alias Billing.Products
  alias Billing.Carts
  alias BillingWeb.SharedComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.public flash={@flash} current_scope={@current_scope}>
      <.header>
        Product
        <:actions>
          <.link :if={@cart_size > 0} navigate={~p"/cart"} class="btn btn-primary">
            <.icon name="hero-shopping-cart" /> {@cart_size}
          </.link>
        </:actions>
      </.header>

      <.button phx-click={JS.push("add_to_cart", value: %{id: @product.id})}>
        Add to Cart
      </.button>

      <SharedComponents.markdown text={@product.content} />

      <div>
        <img :for={file <- @product.files} src={file} alt={@product.name} loading="lazy" />
      </div>
    </Layouts.public>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Products")
     |> assign(:cart_size, cart_size(socket.assigns.cart_uuid))
     |> assign(:product, Products.get_product!(id))}
  end

  @impl true
  def handle_event("add_to_cart", _params, socket) do
    product = socket.assigns.product

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

  defp cart_size(cart_uuid) do
    Enum.count(Carts.list_carts(cart_uuid))
  end
end
