defmodule BillingWeb.CompanyLive.Show do
  use BillingWeb, :live_view

  alias Billing.Companies

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Company {@company.id}
        <:subtitle>This is a company record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/companies"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/companies/#{@company}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit company
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Identification number">{@company.identification_number}</:item>
        <:item title="Address">{@company.address}</:item>
        <:item title="Name">{@company.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Company")
     |> assign(:company, Companies.get_company!(id))}
  end
end
