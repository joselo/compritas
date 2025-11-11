defmodule BillingWeb.ProductLive.Index do
  use BillingWeb, :live_view

  alias Billing.Products

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Products")}
        <:actions>
          <.button variant="primary" navigate={~p"/products/new"}>
            <.icon name="hero-plus" /> {gettext("New Product")}
          </.button>
        </:actions>
      </.header>

      <.table
        id="products"
        rows={@streams.products}
        row_click={fn {_id, product} -> JS.navigate(~p"/products/#{product}") end}
      >
        <:col :let={{_id, product}} label={gettext("Id")}>{product.id}</:col>
        <:col :let={{_id, product}} label={gettext("Name")}>{product.name}</:col>
        <:col :let={{_id, product}} label={gettext("Price")}>{product.price}</:col>
        <:action :let={{_id, product}}>
          <div class="sr-only">
            <.link navigate={~p"/products/#{product}"}>{gettext("Show")}</.link>
          </div>
          <.link navigate={~p"/products/#{product}/edit"}>{gettext("Edit")}</.link>
        </:action>
        <:action :let={{id, product}}>
          <.link
            phx-click={JS.push("delete", value: %{id: product.id}) |> hide("##{id}")}
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
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
     |> stream(:products, list_products(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Products.get_product!(socket.assigns.current_scope, id)
    {:ok, _} = Products.delete_product(socket.assigns.current_scope, product)

    {:noreply, stream_delete(socket, :products, product)}
  end

  defp list_products(current_scope) do
    Products.list_products(current_scope)
  end
end
