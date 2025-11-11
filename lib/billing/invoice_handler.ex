defmodule Billing.InvoiceHandler do
  alias Billing.Quotes
  alias Billing.Invoicing
  alias Billing.TaxiDriver
  alias Billing.ElectronicInvoices
  alias Billing.EmissionProfiles
  alias Billing.Quotes.ElectronicInvoice
  alias Phoenix.PubSub
  alias Billing.ElectronicInvoiceCheckerWorker
  alias Billing.ElectronicInvoicePdfWorker
  alias Billing.InvoicingWorker

  def sign_electronic_invoice(current_scope, quote_id) do
    quote = Quotes.get_quote!(current_scope, quote_id)
    certificate = Billing.Invoicing.fetch_certificate(quote)

    with {:ok, _p12_path} <- p12_file_exists?(certificate.file),

         # Increment the emoission profile sequence
         {:ok, _emission_profile} <-
           increment_emission_profile_sequence(current_scope, quote.emission_profile_id),

         # Build Invoice params
         {:ok, invoice_params} <- Invoicing.build_request_params(quote),

         # Electronic Invoice :created
         {:ok, electronic_invoice} <-
           create_electronic_invoice(current_scope, quote, invoice_params) do
      sign_xml(current_scope, electronic_invoice, certificate)
    else
      {:error, error} ->
        {:error, error}
    end
  end

  # Electronic Invoice :send | :back | :error
  def send_electronic_invoice(current_scope, electronic_invoice_id) do
    electronic_invoice =
      ElectronicInvoices.get_electronic_invoice!(current_scope, electronic_invoice_id)

    # Electronic Invoice :send | :back | :error

    with {:ok, electronic_invoice} <- send_invoice(current_scope, electronic_invoice),
         {:ok, _electronic_invoice_id} <- broadcast_success(electronic_invoice),

         # Run authorization checker using oban worker
         {:ok, _oban_job} <- start_authorization_checker(current_scope, electronic_invoice) do
      {:ok, electronic_invoice}
    else
      {:error, error} ->
        broadcast_error(electronic_invoice.id, error)

        {:error, error}
    end
  end

  def auth_electronic_invoice(current_scope, electronic_invoice_id) do
    electronic_invoice =
      ElectronicInvoices.get_electronic_invoice!(current_scope, electronic_invoice_id)

    # Electronic Invoice :authorized | :unauthorized | :error | :not_found_or_pending

    with {:ok, electronic_invoice} <- verify_authorization(current_scope, electronic_invoice),
         {:ok, _invoice_id} <- broadcast_success(electronic_invoice),
         {:ok, _oban_job} <- run_pdf_worker(current_scope, electronic_invoice) do
      {:ok, electronic_invoice}
    else
      {:error, error} ->
        broadcast_error(electronic_invoice.id, error)

        {:error, error}
    end
  end

  def handle_electronic_invoice_pdf(current_scope, electronic_invoice_id) do
    electronic_invoice =
      ElectronicInvoices.get_electronic_invoice!(current_scope, electronic_invoice_id)

    case create_pdf(electronic_invoice) do
      {:ok, pdf_file_path} ->
        {:ok, pdf_file_path}

      {:error, error} ->
        broadcast_error(electronic_invoice.id, error)

        {:error, error}
    end
  end

  # Electronic Invoice :created

  def create_electronic_invoice(current_scope, quote, invoice_params) do
    with {:ok, body: xml, access_key: access_key} <- TaxiDriver.build_invoice_xml(invoice_params),
         {:ok, _xml_path} <- save_xml(xml, access_key) do
      ElectronicInvoices.create_electronic_invoice(current_scope, quote, access_key)
    else
      error -> error
    end
  end

  # Electronic Invoice :signed

  def sign_xml(
        current_scope,
        %ElectronicInvoice{state: :created} = electronic_invoice,
        certificate
      ) do
    xml_path = xml_path(electronic_invoice.access_key)

    with {:ok, signed_xml} <- TaxiDriver.sign_invoice_xml(xml_path, certificate),
         {:ok, electronic_invoice} <-
           ElectronicInvoices.update_electronic_invoice(
             current_scope,
             electronic_invoice,
             :signed
           ),
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

  defp send_invoice(current_scope, %ElectronicInvoice{state: :signed} = electronic_invoice) do
    xml_signed_path = xml_signed_path(electronic_invoice.access_key)

    with {:ok, body: response_xml, sri_status: sri_status} <-
           TaxiDriver.send_invoice_xml(xml_signed_path),
         {:ok, electronic_invoice} <-
           ElectronicInvoices.update_electronic_invoice(
             current_scope,
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

  defp send_invoice(_current_scope, _electronic_invoice) do
    {:error, "Factura no firmada"}
  end

  # Electronic Invoice :authorized | :unauthorized | :error | :not_found_or_pending

  defp verify_authorization(current_scope, %ElectronicInvoice{state: state} = electronic_invoice)
       when state in [:sent, :not_found_or_pending] do
    with {:ok, body: auth_xml, sri_status: sri_status} <-
           TaxiDriver.auth_invoice(electronic_invoice.access_key),
         {:ok, electronic_invoice} <-
           ElectronicInvoices.update_electronic_invoice(
             current_scope,
             electronic_invoice,
             ElectronicInvoice.determinate_status(sri_status)
           ),
         {:ok, _auth_xml_path} <- save_auth_response_xml(auth_xml, electronic_invoice.access_key) do
      {:ok, electronic_invoice}
    else
      error -> error
    end
  end

  defp verify_authorization(
         _current_scope,
         %ElectronicInvoice{state: :authorized} = _electronic_invoice
       ) do
    {:error, "La Factura ya fue autorizada"}
  end

  defp verify_authorization(_current_scope, _electronic_invoice) do
    {:error, "Factura no autorizada"}
  end

  # Update Emission profile sequence

  defp increment_emission_profile_sequence(current_scope, emission_profile_id) do
    emission_profile = EmissionProfiles.get_emission_profile!(current_scope, emission_profile_id)

    new_sequence = emission_profile.sequence + 1

    EmissionProfiles.update_emission_profile(current_scope, emission_profile, %{
      sequence: new_sequence
    })
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

  defp broadcast_success(electronic_invoice) do
    PubSub.broadcast(
      Billing.PubSub,
      "electronic_invoice:#{electronic_invoice.id}",
      {:electronic_invoice_updated, %{electronic_invoice_id: electronic_invoice.id}}
    )

    PubSub.broadcast(
      Billing.PubSub,
      "quote:#{electronic_invoice.quote_id}",
      {:electronic_invoice_updated, %{electronic_invoice_id: electronic_invoice.id}}
    )

    {:ok, electronic_invoice}
  end

  def broadcast_error(electronic_invoice, error) do
    PubSub.broadcast(
      Billing.PubSub,
      "electronic_invoice_id:#{electronic_invoice.id}",
      {:electronic_invoice_error,
       %{electronic_invoice_id: electronic_invoice.id, error: inspect(error)}}
    )

    PubSub.broadcast(
      Billing.PubSub,
      "quote_id:#{electronic_invoice.quote_id}",
      {:electronic_invoice_error,
       %{electronic_invoice_id: electronic_invoice.id, error: inspect(error)}}
    )

    {:error, error}
  end

  # Workers

  def start_authorization_checker(
        current_scope,
        %ElectronicInvoice{state: :sent} = electronic_invoice
      ) do
    %{"user_id" => current_scope.user.id, "electronic_invoice_id" => electronic_invoice.id}
    |> ElectronicInvoiceCheckerWorker.new()
    |> Oban.insert()
  end

  def start_authorization_checker(_current_scope, %ElectronicInvoice{state: _state}) do
    {:ok, nil}
  end

  def start_send_worker(current_scope, %ElectronicInvoice{state: :signed} = electronic_invoice) do
    %{"user_id" => current_scope.user.id, "electronic_invoice_id" => electronic_invoice.id}
    |> InvoicingWorker.new()
    |> Oban.insert()
  end

  def start_send_worker(_current_scope, %ElectronicInvoice{state: _state}) do
    {:ok, nil}
  end

  def run_pdf_worker(current_scope, %ElectronicInvoice{state: :authorized} = electronic_invoice) do
    %{"user_id" => current_scope.user.id, "electronic_invoice_id" => electronic_invoice.id}
    |> ElectronicInvoicePdfWorker.new()
    |> Oban.insert()
  end

  def run_pdf_worker(_current_scope, %ElectronicInvoice{state: _state}) do
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
