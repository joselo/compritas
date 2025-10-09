defmodule Billing.InvoiceHandler do
  alias Billing.Invoices
  alias Billing.Invoicing
  alias Billing.TaxiDriver
  alias Billing.ElectronicInvoices
  alias Billing.EmissionProfiles
  alias Billing.Invoices.ElectronicInvoice

  def handle_invoice(invoice_id) do
    invoice = Invoices.get_invoice!(invoice_id)
    certificate = Billing.Invoicing.fetch_certificate(invoice)

    with {:ok, invoice_params} <- Invoicing.build_request_params(invoice),
         {:ok, body: xml, access_key: access_key} <- TaxiDriver.build_invoice_xml(invoice_params),
         {:ok, electronic_invoice} <-
           ElectronicInvoices.create_electronic_invoice(invoice.id, access_key),
         {:ok, xml_path} <- save_xml(xml, access_key),
         {:ok, signed_xml} <- TaxiDriver.sign_invoice_xml(xml_path, certificate),
         {:ok, _electronic_invoice} <-
           ElectronicInvoices.update_electronic_invoice(electronic_invoice, :signed),
         {:ok, signed_xml_path} <- save_signed_xml(signed_xml, access_key),
         {:ok, body: response_xml, sri_status: sri_status} <-
           TaxiDriver.send_invoice_xml(signed_xml_path),
         {:ok, _electronic_invoice} <-
           ElectronicInvoices.update_electronic_invoice(
             electronic_invoice,
             ElectronicInvoice.determinate_status(sri_status)
           ),
         {:ok, _response_xml_path} <- save_response_xml(response_xml, access_key),
         {:ok, body: auth_xml, sri_status: sri_status} <- TaxiDriver.auth_invoice(access_key),
         {:ok, _electronic_invoice} <-
           ElectronicInvoices.update_electronic_invoice(
             electronic_invoice,
             ElectronicInvoice.determinate_status(sri_status)
           ),
         {:ok, auth_xml_path} <- save_auth_response_xml(auth_xml, access_key),
         {:ok, pdf_content} <- TaxiDriver.pdf_invoice_xml(auth_xml_path),
         {:ok, _pdf_file_path} <- save_pdf_file(pdf_content, access_key),
         {:ok, emission_profile} <-
           increment_emission_profile_sequence(invoice.emission_profile_id) do
      {:ok, emission_profile}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp save_xml(xml, access_key) do
    path = "#{Billing.get_storage_path()}/#{access_key}.xml"
    File.write(path, xml)

    {:ok, path}
  end

  defp save_signed_xml(xml, access_key) do
    path = "#{Billing.get_storage_path()}/#{access_key}-signed.xml"
    File.write(path, xml)

    {:ok, path}
  end

  defp save_response_xml(xml, access_key) do
    path = "#{Billing.get_storage_path()}/#{access_key}-response.xml"
    File.write(path, xml)

    {:ok, path}
  end

  defp save_auth_response_xml(xml, access_key) do
    path = "#{Billing.get_storage_path()}/#{access_key}-auth.xml"
    File.write(path, xml)

    {:ok, path}
  end

  defp save_pdf_file(pdf_content, access_key) do
    path = "#{Billing.get_storage_path()}/#{access_key}.pdf"
    File.write(path, pdf_content)

    {:ok, path}
  end

  defp increment_emission_profile_sequence(emission_profile_id) do
    emission_profile = EmissionProfiles.get_emission_profile!(emission_profile_id)

    new_sequence = emission_profile.sequence + 1

    EmissionProfiles.update_emission_profile(emission_profile, %{sequence: new_sequence})
  end
end
