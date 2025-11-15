defmodule BillingWeb.ProductLive.Show do
  use BillingWeb, :live_view

  import Billing.Storage, only: [cdn_url: 1]

  alias Billing.Products
  alias BillingWeb.SharedComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      return_to={~p"/products"}
      settings={@settings}
    >
      <.header>
        {gettext("Product #%{product_id}", product_id: @product.id)}
        <:subtitle>{@product.inserted_at}</:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/products/#{@product}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> {gettext("Edit product")}
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title={gettext("Name")}>{@product.name}</:item>
        <:item title={gettext("Price")}>{@product.price}</:item>
      </.list>

      <SharedComponents.markdown text={@product.content} />

      <div>
        <img :for={file <- @product.files} src={cdn_url(file)} loading="lazy" />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Product #%{product_id}", product_id: id))
     |> assign(:product, Products.get_product!(socket.assigns.current_scope, id))}
  end
end
