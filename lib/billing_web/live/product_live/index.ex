defmodule BillingWeb.ProductLive.Index do
  use BillingWeb, :live_view

  alias Billing.Products

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Products
        <:actions>
          <.button variant="primary" navigate={~p"/products/new"}>
            <.icon name="hero-plus" /> New Product
          </.button>
        </:actions>
      </.header>

      <.table
        id="products"
        rows={@streams.products}
        row_click={fn {_id, product} -> JS.navigate(~p"/products/#{product}") end}
      >
        <:col :let={{_id, product}} label="Name">{product.name}</:col>
        <:col :let={{_id, product}} label="Price">{product.price}</:col>
        <:action :let={{_id, product}}>
          <div class="sr-only">
            <.link navigate={~p"/products/#{product}"}>Show</.link>
          </div>
          <.link navigate={~p"/products/#{product}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, product}}>
          <.link
            phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
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
  def handle_event("delete", %{"id" => id}, socket) do
    product = Products.get_product!(id)
    {:ok, _} = Products.delete_product(product)

    {:noreply, stream_delete(socket, :products, product)}
  end

  defp list_products() do
    Products.list_products()
  end
end
