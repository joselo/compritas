defmodule BillingWeb.CertificateLive.Index do
  use BillingWeb, :live_view

  alias Billing.Certificates

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Certificates
        <:actions>
          <.button variant="primary" navigate={~p"/certificates/new"}>
            <.icon name="hero-plus" /> New Certificate
          </.button>
        </:actions>
      </.header>

      <.table
        id="certificates"
        rows={@streams.certificates}
        row_click={fn {_id, certificate} -> JS.navigate(~p"/certificates/#{certificate}") end}
      >
        <:col :let={{_id, certificate}} label="Name">{certificate.name}</:col>
        <:col :let={{_id, certificate}} label="File">{certificate.file}</:col>
        <:action :let={{_id, certificate}}>
          <div class="sr-only">
            <.link navigate={~p"/certificates/#{certificate}"}>Show</.link>
          </div>
          <.link navigate={~p"/certificates/#{certificate}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, certificate}}>
          <.link
            phx-click={JS.push("delete", value: %{id: certificate.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
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
     |> assign(:page_title, "Listing Certificates")
     |> stream(:certificates, Certificates.list_certificates())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    certificate = Certificates.get_certificate!(id)
    {:ok, _} = Certificates.delete_certificate(certificate)

    {:noreply, stream_delete(socket, :certificates, certificate)}
  end
end
