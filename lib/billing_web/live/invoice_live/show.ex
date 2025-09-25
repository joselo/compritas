defmodule BillingWeb.InvoiceLive.Show do
  use BillingWeb, :live_view

  alias Billing.Invoices
  alias Billing.Invoicing
  alias Billing.TaxiDriver
  alias Billing.ElectronicInvoices
  alias Billing.EmissionProfiles

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Invoice {@invoice.id}
        <:subtitle>This is a invoice record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/invoices"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/invoices/#{@invoice}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit invoice
          </.button>
          <.button phx-click="sign_xml">
            <.icon name="hero-pencil-square" /> Crear Factura
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Issued at">{@invoice.issued_at}</:item>
        <:item title="Customer">{@invoice.customer.full_name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Invoice")
     |> assign(:invoice, Invoices.get_invoice!(id))}
  end

  @impl true
  def handle_event("sign_xml", _params, socket) do
    certificate = Billing.Invoicing.fetch_certificate(socket.assigns.invoice)

    with {:ok, invoice_params} <- Invoicing.build_request_params(socket.assigns.invoice),
         {:ok, body: xml, access_key: access_key} <- TaxiDriver.build_invoice_xml(invoice_params),
         {:ok, electronic_invoice} <- ElectronicInvoices.create_electronic_invoice(socket.assigns.invoice.id, access_key),
         {:ok, xml_path} <- save_xml(xml, access_key),
         {:ok, signed_xml} <- TaxiDriver.sing_invoice_xml(xml_path, certificate),
         {:ok, _electronic_invoice} <- ElectronicInvoices.update_electronic_invoice(electronic_invoice, :signed),
         {:ok, signed_xml_path} <- save_signed_xml(signed_xml, access_key),
         {:ok, response_xml} <- TaxiDriver.send_invoice_xml(signed_xml_path),
         {:ok, _electronic_invoice} <- ElectronicInvoices.update_electronic_invoice(electronic_invoice, :sent),
         {:ok, _response_xml_path} <- save_response_xml(response_xml, access_key),
         {:ok, body: auth_xml, sri_status: sri_status} <- TaxiDriver.auth_invoice(access_key),
         {:ok, _electronic_invoice} <- ElectronicInvoices.update_electronic_invoice(electronic_invoice, :auth),
         {:ok, auth_xml_path} <- save_auth_response_xml(auth_xml, access_key),
         {:ok, pdf_content} <- TaxiDriver.pdf_invoice_xml(auth_xml_path),
         {:ok, pdf_file_path} <- save_pdf_file(pdf_content, access_key),
         {:ok, emission_profile} <- increment_emission_profile_sequence(socket.assigns.invoice.emission_profile_id) do
      IO.inspect("--------")
      IO.inspect(pdf_file_path)
      IO.inspect("--------")
      IO.inspect(sri_status)
      IO.inspect("--------")
      IO.inspect(emission_profile)
      IO.inspect("--------")

      {:noreply, put_flash(socket, :info, "Xml success!!")}
    else
      {:error, error} ->
        {:noreply, put_flash(socket, :error, "Xml error: #{inspect(error)}")}
    end
  end

  defp save_xml(xml, access_key) do
    path = "#{get_storage_path()}/#{access_key}.xml"
    File.write(path, xml)

    {:ok, path}
  end

  defp save_signed_xml(xml, access_key) do
    path = "#{get_storage_path()}/#{access_key}-signed.xml"
    File.write(path, xml)

    {:ok, path}
  end

  defp save_response_xml(xml, access_key) do
    path = "#{get_storage_path()}/#{access_key}-response.xml"
    File.write(path, xml)

    {:ok, path}
  end

  defp save_auth_response_xml(xml, access_key) do
    path = "#{get_storage_path()}/#{access_key}-auth.xml"
    File.write(path, xml)

    {:ok, path}
  end

  defp save_pdf_file(pdf_content, access_key) do
    path = "#{get_storage_path()}/#{access_key}.pdf"
    File.write(path, pdf_content)

    {:ok, path}
  end

  defp get_storage_path do
    Application.get_env(:billing, :storage_path)
  end

  defp increment_emission_profile_sequence(emission_profile_id) do
    emission_profile = EmissionProfiles.get_emission_profile!(emission_profile_id)

    new_sequence = emission_profile.sequence + 1

    EmissionProfiles.update_emission_profile(emission_profile, %{sequence: new_sequence})
  end
end
