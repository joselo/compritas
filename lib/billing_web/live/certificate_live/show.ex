defmodule BillingWeb.CertificateLive.Show do
  use BillingWeb, :live_view

  alias Billing.Certificates

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Certificate {@certificate.id}
        <:subtitle>This is a certificate record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/certificates"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/certificates/#{@certificate}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit certificate
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
     |> assign(:page_title, "Show Certificate")
     |> assign(:certificate, Certificates.get_certificate!(id))}
  end
end
