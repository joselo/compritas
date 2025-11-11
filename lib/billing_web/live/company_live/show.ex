defmodule BillingWeb.CompanyLive.Show do
  use BillingWeb, :live_view

  alias Billing.Companies

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} return_to={~p"/companies"}>
      <.header>
        {gettext("Company #%{company_id}", company_id: @company.id)}
        <:subtitle>{@company.inserted_at}</:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/companies/#{@company}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> {gettext("Edit company")}
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title={gettext("Identification number")}>{@company.identification_number}</:item>
        <:item title={gettext("Address")}>{@company.address}</:item>
        <:item title={gettext("Name")}>{@company.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Company #%{company_id}", company_id: id))
     |> assign(:company, Companies.get_company!(socket.assigns.current_scope, id))}
  end
end
