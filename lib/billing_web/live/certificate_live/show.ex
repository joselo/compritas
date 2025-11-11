defmodule BillingWeb.CertificateLive.Show do
  use BillingWeb, :live_view

  alias Billing.Certificates

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} return_to={~p"/certificates"}>
      <.header>
        {gettext("Certificates #%{certificate_id}", certificate_id: @certificate.id)}
        <:subtitle>{@certificate.inserted_at}</:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/certificates/#{@certificate}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> {gettext("Edit certificate")}
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@certificate.name}</:item>
      </.list>

      <.list>
        <:item title="File">{@certificate.file}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Certificate #%{certificate_id}", certificate_id: id))
     |> assign(:certificate, Certificates.get_certificate!(socket.assigns.current_scope, id))}
  end
end
