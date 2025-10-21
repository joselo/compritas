defmodule BillingWeb.OrderLive.Index do
  use BillingWeb, :live_view

  alias Billing.Orders

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Orders
      </.header>

      <.table
        id="orders"
        rows={@streams.orders}
        row_click={fn {_id, order} -> JS.navigate(~p"/orders/#{order}") end}
      >
        <:col :let={{_id, order}} label="Name">{order.full_name}</:col>
        <:col :let={{_id, order}} label="Price">{order.phone_number}</:col>
        <:action :let={{_id, order}}>
          <div class="sr-only">
            <.link navigate={~p"/orders/#{order}"}>Show</.link>
          </div>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Orders")
     |> stream(:orders, list_orders())}
  end

  defp list_orders() do
    Orders.list_orders()
  end
end
