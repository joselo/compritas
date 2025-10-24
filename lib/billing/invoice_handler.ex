defmodule Billing.InvoiceHandler do
  alias Billing.Invoices
  alias Billing.Invoicing
  alias Billing.TaxiDriver
  alias Billing.ElectronicInvoices
  alias Billing.EmissionProfiles
  alias Billing.Invoices.ElectronicInvoice
  alias Phoenix.PubSub
  alias Billing.ElectronicInvoiceCheckerWorker
  alias Billing.ElectronicInvoicePdfWorker

  def build_electronic_invoice(invoice_id) do
    invoice = Invoices.get_invoice!(invoice_id)
    certificate = Billing.Invoicing.fetch_certificate(invoice)

    with {:ok, _p12_path} <- p12_file_exists?(certificate.file),

         # Increment the emoission profile sequence
         {:ok, _emission_profile} <-
           increment_emission_profile_sequence(invoice.emission_profile_id),

         # Build Invoice params
         {:ok, invoice_params} <- Invoicing.build_request_params(invoice),

         # Electronic Invoice :created
         {:ok, electronic_invoice} <- create_electronic_invoice(invoice.id, invoice_params) do
      sign_xml(electronic_invoice, certificate)
    else
      {:error, error} ->
        {:error, error}
    end
  end

  def handle_electronic_invoice(electronic_invoice_id) do
    electronic_invoice = ElectronicInvoices.get_electronic_invoice!(electronic_invoice_id)
    # Electronic Invoice :send | :back | :error
    with {:ok, electronic_invoice} <- send_invoice(electronic_invoice),
         {:ok, _invoice_id} <- broadcast_success(electronic_invoice.id),

         # Run authorization checker using oban worker
         {:ok, _oban_job} <- run_authorization_checker(electronic_invoice) do
      {:ok, electronic_invoice}
    else
      {:error, error} ->
        # broadcast_error(invoice_id, error)

        {:error, error}
    end
  end

  def handle_auth_invoice(electronic_invoice_id) do
    electronic_invoice = ElectronicInvoices.get_electronic_invoice!(electronic_invoice_id)
    invoice = Invoices.get_invoice!(electronic_invoice.invoice_id)

    # Electronic Invoice :authorized | :unauthorized | :error | :not_found_or_pending

    with {:ok, electronic_invoice} <- verify_authorization(electronic_invoice),
         {:ok, _invoice_id} <- broadcast_success(invoice.id),
         {:ok, _oban_job} <- run_pdf_worker(electronic_invoice) do
      {:ok, electronic_invoice}
    else
      {:error, error} ->
        broadcast_error(electronic_invoice.id, error)

        {:error, error}
    end
  end

  def handle_invoice_pdf(electronic_invoice_id) do
    electronic_invoice = ElectronicInvoices.get_electronic_invoice!(electronic_invoice_id)

    case create_pdf(electronic_invoice) do
      {:ok, pdf_file_path} ->
        {:ok, pdf_file_path}

      {:error, error} ->
        broadcast_error(electronic_invoice.id, error)

        {:error, error}
    end
  end

  # Electronic Invoice :created

  def create_electronic_invoice(invoice_id, invoice_params) do
    with {:ok, body: xml, access_key: access_key} <- TaxiDriver.build_invoice_xml(invoice_params),
         {:ok, _xml_path} <- save_xml(xml, access_key) do
      ElectronicInvoices.create_electronic_invoice(invoice_id, access_key)
    else
      error -> error
    end
  end

  # Electronic Invoice :signed

  def sign_xml(%ElectronicInvoice{state: :created} = electronic_invoice, certificate) do
    xml_path = xml_path(electronic_invoice.access_key)

    with {:ok, signed_xml} <- TaxiDriver.sign_invoice_xml(xml_path, certificate),
         {:ok, electronic_invoice} <-
           ElectronicInvoices.update_electronic_invoice(electronic_invoice, :signed),
         {:ok, _signed_xml_path} <- save_signed_xml(signed_xml, electronic_invoice.access_key) do
      {:ok, electronic_invoice}
    else
      error -> error
    end
  end

  def sign_xml(_electronic_invoice, _certificate) do
    {:error, "Factura no creada"}
  end

  # Electronic Invoice :send | :back | :error

  defp send_invoice(%ElectronicInvoice{state: :signed} = electronic_invoice) do
    xml_signed_path = xml_signed_path(electronic_invoice.access_key)

    with {:ok, body: response_xml, sri_status: sri_status} <-
           TaxiDriver.send_invoice_xml(xml_signed_path),
         {:ok, electronic_invoice} <-
           ElectronicInvoices.update_electronic_invoice(
             electronic_invoice,
             ElectronicInvoice.determinate_status(sri_status)
           ),
         {:ok, _response_xml_path} <-
           save_response_xml(response_xml, electronic_invoice.access_key) do
      {:ok, electronic_invoice}
    else
      error -> error
    end
  end

  defp send_invoice(_electronic_invoice) do
    {:error, "Factura no firmada"}
  end

  # Electronic Invoice :authorized | :unauthorized | :error | :not_found_or_pending

  defp verify_authorization(%ElectronicInvoice{state: state} = electronic_invoice)
       when state in [:sent, :not_found_or_pending] do
    with {:ok, body: auth_xml, sri_status: sri_status} <-
           TaxiDriver.auth_invoice(electronic_invoice.access_key),
         {:ok, electronic_invoice} <-
           ElectronicInvoices.update_electronic_invoice(
             electronic_invoice,
             ElectronicInvoice.determinate_status(sri_status)
           ),
         {:ok, _auth_xml_path} <- save_auth_response_xml(auth_xml, electronic_invoice.access_key) do
      {:ok, electronic_invoice}
    else
      error -> error
    end
  end

  defp verify_authorization(%ElectronicInvoice{state: :authorized} = electronic_invoice) do
    {:ok, electronic_invoice}
  end

  defp verify_authorization(_electronic_invoice) do
    {:error, "Factura no autorizada"}
  end

  # Update Emission profile sequence

  defp increment_emission_profile_sequence(emission_profile_id) do
    emission_profile = EmissionProfiles.get_emission_profile!(emission_profile_id)

    new_sequence = emission_profile.sequence + 1

    EmissionProfiles.update_emission_profile(emission_profile, %{sequence: new_sequence})
  end

  # Electronic Invoice: PDF

  defp create_pdf(%ElectronicInvoice{state: :authorized} = electronic_invoice) do
    xml_auth_path = xml_auth_path(electronic_invoice.access_key)

    case TaxiDriver.pdf_invoice_xml(xml_auth_path) do
      {:ok, pdf_content} ->
        save_pdf_file(pdf_content, electronic_invoice.access_key)

      error ->
        error
    end
  end

  defp create_pdf(_electronic_invoice) do
    {:error, "Factura no autorizada"}
  end

  # Store files paths

  def xml_path(access_key) do
    "#{Billing.get_storage_path()}/#{access_key}.xml"
  end

  def xml_signed_path(access_key) do
    "#{Billing.get_storage_path()}/#{access_key}-signed.xml"
  end

  def xml_response_path(access_key) do
    "#{Billing.get_storage_path()}/#{access_key}-response.xml"
  end

  def xml_auth_path(access_key) do
    "#{Billing.get_storage_path()}/#{access_key}-auth.xml"
  end

  def pdf_path(access_key) do
    "#{Billing.get_storage_path()}/#{access_key}.pdf"
  end

  # Store files section

  defp save_xml(xml, access_key) do
    path = xml_path(access_key)
    File.write(path, xml)

    {:ok, path}
  end

  defp save_signed_xml(xml, access_key) do
    path = xml_signed_path(access_key)
    File.write(path, xml)

    {:ok, path}
  end

  defp save_response_xml(xml, access_key) do
    path = xml_response_path(access_key)
    File.write(path, xml)

    {:ok, path}
  end

  defp save_auth_response_xml(xml, access_key) do
    path = xml_auth_path(access_key)
    File.write(path, xml)

    {:ok, path}
  end

  defp save_pdf_file(pdf_content, access_key) do
    path = pdf_path(access_key)
    File.write(path, pdf_content)

    {:ok, path}
  end

  # Broadcast section

  defp broadcast_success(electronic_invoice_id) do
    PubSub.broadcast(
      Billing.PubSub,
      "electronic_invoice:#{electronic_invoice_id}",
      {:update_electronic_invoice, %{electronic_invoice_id: electronic_invoice_id}}
    )

    {:ok, electronic_invoice_id}
  end

  def broadcast_error(electronic_invoice_id, error) do
    PubSub.broadcast(
      Billing.PubSub,
      "electronic_invoice_id:#{electronic_invoice_id}",
      {:electronic_invoice_error,
       %{electronic_invoice_id: electronic_invoice_id, error: inspect(error)}}
    )

    {:error, error}
  end

  # Workers

  def run_authorization_checker(%ElectronicInvoice{state: :sent} = electronic_invoice) do
    %{"electronic_invoice_id" => electronic_invoice.id}
    |> ElectronicInvoiceCheckerWorker.new()
    |> Oban.insert()
  end

  def run_authorization_checker(%ElectronicInvoice{state: _state}) do
    {:ok, nil}
  end

  def run_pdf_worker(%ElectronicInvoice{state: :authorized} = electronic_invoice) do
    %{"electronic_invoice_id" => electronic_invoice.id}
    |> ElectronicInvoicePdfWorker.new()
    |> Oban.insert()
  end

  def run_pdf_worker(%ElectronicInvoice{state: _state}) do
    {:ok, nil}
  end

  defp p12_file_exists?(p12_file_path) do
    p12_path = Path.join(Billing.get_storage_path(), p12_file_path)

    if File.exists?(p12_path) do
      {:ok, p12_path}
    else
      {:error, "El certificado para firmar la factura no existe"}
    end
  end
end
