defmodule BillingWeb.ProductLive.Show do
  use BillingWeb, :live_view

  alias Billing.Products

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Product {@product.id}
        <:subtitle>This is a product record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/products"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/products/#{@product}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit product
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@product.name}</:item>
        <:item title="Price">{@product.price}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Product")
     |> assign(:product, Products.get_product!(id))}
  end
end
