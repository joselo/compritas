defmodule BillingWeb.CompanyLive.Index do
  use BillingWeb, :live_view

  alias Billing.Companies

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Companies")}
        <:actions>
          <.button variant="primary" navigate={~p"/companies/new"}>
            <.icon name="hero-plus" /> {gettext("New Company")}
          </.button>
        </:actions>
      </.header>

      <.table
        id="companies"
        rows={@streams.companies}
        row_click={fn {_id, company} -> JS.navigate(~p"/companies/#{company}") end}
      >
        <:col :let={{_id, company}} label={gettext("Id")}>{company.id}</:col>
        <:col :let={{_id, company}} label={gettext("Identification number")}>
          {company.identification_number}
        </:col>
        <:col :let={{_id, company}} label={gettext("Address")}>{company.address}</:col>
        <:col :let={{_id, company}} label={gettext("Name")}>{company.name}</:col>
        <:action :let={{_id, company}}>
          <div class="sr-only">
            <.link navigate={~p"/companies/#{company}"}>{gettext("Show")}</.link>
          </div>
          <.link navigate={~p"/companies/#{company}/edit"}>{gettext("Edit")}</.link>
        </:action>
        <:action :let={{id, company}}>
          <.link
            phx-click={JS.push("delete", value: %{id: company.id}) |> hide("##{id}")}
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
     |> assign(:page_title, gettext("Companies"))
     |> stream(:companies, Companies.list_companies(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    company = Companies.get_company!(socket.assigns.current_scope, id)
    {:ok, _} = Companies.delete_company(socket.assigns.current_scope, company)

    {:noreply, stream_delete(socket, :companies, company)}
  end
end
