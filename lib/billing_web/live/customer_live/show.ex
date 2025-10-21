defmodule BillingWeb.CustomerLive.Show do
  use BillingWeb, :live_view

  alias Billing.Customers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Customer {@customer.id}
        <:subtitle>This is a customer record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/customers"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/customers/#{@customer}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit customer
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Full name">{@customer.full_name}</:item>
        <:item title="Email">{@customer.email}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Customer")
     |> assign(:customer, Customers.get_customer!(id))}
  end
end
