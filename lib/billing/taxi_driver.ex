defmodule Billing.TaxiDriver do
  @invoice_url "https://api.taxideral.com/facturas"
  @sign_invoice_url "https://api.taxideral.com/firmar"

  @headers [
    {"Content-Type", "application/json"},
    {"accept", "application/xml"}
  ]

  def build_invoice_xml(invoice_params) do
    json_body = Jason.encode!(invoice_params)

    case HTTPoison.post(@invoice_url, json_body, @headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, %{status_code: status_code, body: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def sing_invoice_xml(xml_path, certificate) do
    p12_path = "/home/joselo/Facturacion/billing/priv/static/uploads/#{certificate.file}"

    multipart_body = [
      {"p12_password", certificate.password},
      {:file, p12_path, {"form-data", [name: "p12_file", filename: Path.basename(p12_path)]},
       [{"Content-Type", "text/plain"}]},
      {:file, xml_path, {"form-data", [name: "xml_file", filename: Path.basename(xml_path)]},
       [{"Content-Type", "text/plain"}]}
    ]

    headers = [{"Content-Type", "multipart/form-data"}]

    case HTTPoison.post(@sign_invoice_url, {:multipart, multipart_body}, headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, %{status_code: status_code, body: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
