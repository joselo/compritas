defmodule BillingWeb.OrderLive.Show do
  use BillingWeb, :live_view

  alias Billing.Orders

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} return_to={~p"/orders"}>
      <.header>
        {gettext("Order #%{order_id}", order_id: @order.id)}
        <:subtitle>{@order.inserted_at}</:subtitle>
        <:actions>
          <.link navigate={~p"/quotes/new/#{@order.id}"} class="btn btn-primary">
            <.icon name="hero-plus" /> {gettext("New Quote")}
          </.link>
        </:actions>
      </.header>

      <.list>
        <:item title={gettext("Customer")}>{@order.full_name}</:item>
        <:item title={gettext("Price")}>{@order.phone_number}</:item>
        <:item title={gettext("Amount")}>{@order.amount}</:item>
      </.list>

      <div class="divider">{gettext("Items")}</div>

      <.table
        id="items"
        rows={@order.items}
      >
        <:col :let={item} label={gettext("Product")}>{item.name}</:col>
        <:col :let={item} label={gettext("Price")}>{item.price}</:col>
        <:col :let={item} label={gettext("Quantity")}>{item.quantity}</:col>
        <:col :let={item} label={gettext("Amount")}>{item.amount}</:col>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Order")
     |> assign(:order, Orders.get_order!(socket.assigns.current_scope, id))}
  end
end
