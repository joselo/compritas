defmodule BillingWeb.CustomerLive.Show do
  use BillingWeb, :live_view

  alias Billing.Customers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} return_to={~p"/customers"}>
      <.header>
        {gettext("Customer #%{customer_id}", customer_id: @customer.id)}
        <:subtitle>{@customer.inserted_at}</:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/customers/#{@customer}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> {gettext("Edit customer")}
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title={gettext("Full name")}>{@customer.full_name}</:item>
        <:item title={gettext("Email")}>{@customer.email}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Customer #%{customer_id}", customer_id: id))
     |> assign(:customer, Customers.get_customer!(socket.assigns.current_scope, id))}
  end
end
