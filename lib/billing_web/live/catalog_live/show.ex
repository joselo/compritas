defmodule BillingWeb.CatalogLive.Show do
  use BillingWeb, :live_view

  alias Billing.Products
  alias Billing.Carts
  alias BillingWeb.SharedComponents
  alias BillingWeb.ProductComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.public flash={@flash} current_scope={@current_scope} return_to={~p"/"}>
      <SharedComponents.cart_status cart_size={@cart_size} />

      <.header>
        {@product.name}
        <:subtitle>{@product.price}</:subtitle>

        <:actions>
          <.button phx-click={JS.push("add_to_cart", value: %{id: @product.id})} variant="primary">
            <.icon name="hero-plus" /> {gettext("Add to Cart")}
          </.button>
        </:actions>
      </.header>

      <SharedComponents.markdown text={@product.content} />

      <ProductComponents.gallery title={@product.name} images={@product.files} />
    </Layouts.public>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Products")
     |> assign(:cart_size, cart_size(socket.assigns.cart_uuid))
     |> assign(:product, Products.get_product!(socket.assigns.user_scope, id))}
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
         |> put_flash(
           :info,
           gettext("%{product_name} added to your cart", product_name: product.name)
         )}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, inspect(changeset))}
    end
  end

  defp cart_size(cart_uuid) do
    Enum.count(Carts.list_carts(cart_uuid))
  end
end
