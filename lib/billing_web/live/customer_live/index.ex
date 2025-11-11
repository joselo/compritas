defmodule BillingWeb.CustomerLive.Index do
  use BillingWeb, :live_view

  alias Billing.Customers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Customers")}
        <:actions>
          <.button variant="primary" navigate={~p"/customers/new"}>
            <.icon name="hero-plus" /> {gettext("New Customer")}
          </.button>
        </:actions>
      </.header>

      <.table
        id="customers"
        rows={@streams.customers}
        row_click={fn {_id, customer} -> JS.navigate(~p"/customers/#{customer}") end}
      >
        <:col :let={{_id, customer}} label={gettext("Id")}>{customer.id}</:col>
        <:col :let={{_id, customer}} label={gettext("Full name")}>{customer.full_name}</:col>
        <:col :let={{_id, customer}} label={gettext("Email")}>{customer.email}</:col>
        <:action :let={{_id, customer}}>
          <div class="sr-only">
            <.link navigate={~p"/customers/#{customer}"}>{gettext("Show")}</.link>
          </div>
          <.link navigate={~p"/customers/#{customer}/edit"}>{gettext("Edit")}</.link>
        </:action>
        <:action :let={{id, customer}}>
          <.link
            phx-click={JS.push("delete", value: %{id: customer.id}) |> hide("##{id}")}
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
     |> assign(:page_title, gettext("Customers"))
     |> stream(:customers, Customers.list_customers(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    customer = Customers.get_customer!(socket.assigns.current_scope, id)
    {:ok, _} = Customers.delete_customer(socket.assigns.current_scope, customer)

    {:noreply, stream_delete(socket, :customers, customer)}
  end
end
