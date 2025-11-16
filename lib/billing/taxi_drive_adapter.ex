defmodule Billing.TaxiDriverAdapter do
  def build_invoice_xml(invoice_params) do
    case BillingCore.XmlBuilder.build_invoice(invoice_params[:factura]) do
      {:ok, [xml: xml, clave_acceso: access_key]} ->
        {:ok, body: xml, access_key: access_key}

      {:error, error} ->
        {:error, error}
    end
  end

  def sign_invoice_xml(xml_path, p12_path, p12_password) do
    case BillingCore.Signing.sign(
           File.read!(xml_path),
           p12_path,
           p12_password
         ) do
      {:ok, xml_signed} -> {:ok, xml_signed}
      {:error, error} -> {:error, error}
    end
  end

  def send_invoice_xml(xml_signed_path, environment \\ 1) do
    case BillingCore.SriClient.send_document(
           File.read!(xml_signed_path),
           environment
         ) do
      {:ok, %{status: sri_status, response: response}} ->
        {:ok, body: response, sri_status: sri_status}

      {:error, error} ->
        {:error, error}
    end
  end

  def auth_invoice(access_key, environment \\ 1) do
    case BillingCore.SriClient.is_authorized(
           access_key,
           environment
         ) do
      {:ok, %{status: sri_status, response: response}} ->
        {:ok, body: response, sri_status: sri_status}

      {:error, error} ->
        {:error, error}
    end
  end

  def pdf_invoice_xml(xml_signed_path) do
    xml_parsed = BillingCore.InvoiceXmlParser.parse_xml(File.read!(xml_signed_path))

    case BillingCore.InvoicePdfBuilder.build(xml_parsed) do
      {:error, error} -> {:error, error}
      pdf -> {:ok, pdf}
    end
  end
end
