defmodule Billing.TaxiDriverApiAdapter do
  @invoice_url "https://api.taxideral.com/facturas"
  @sign_invoice_url "https://api.taxideral.com/firmar"
  @send_invoice_url "https://api.taxideral.com/enviar"
  @auth_invoice_url "https://api.taxideral.com/consultar_autorizacion"
  @pdf_invoice_url "https://api.taxideral.com/facturas/pdf"

  @headers [
    {"Content-Type", "application/json"},
    {"accept", "application/xml"}
  ]

  @multipart_headers [{"Content-Type", "multipart/form-data"}]

  def build_invoice_xml(invoice_params) do
    json_body = Jason.encode!(invoice_params)

    case HTTPoison.post(@invoice_url, json_body, @headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body, headers: headers}} ->
        {"x-access-key", access_key} =
          Enum.find(headers, fn {key, _value} -> key == "x-access-key" end)

        {:ok, body: body, access_key: access_key}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, %{status_code: status_code, body: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def sign_invoice_xml(xml_path, p12_path, p12_password) do
    multipart_body = [
      {"p12_password", p12_password},
      {:file, p12_path, {"form-data", [name: "p12_file", filename: Path.basename(p12_path)]},
       [{"Content-Type", "text/plain"}]},
      {:file, xml_path, {"form-data", [name: "xml_file", filename: Path.basename(xml_path)]},
       [{"Content-Type", "text/plain"}]}
    ]

    case HTTPoison.post(@sign_invoice_url, {:multipart, multipart_body}, @multipart_headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, %{status_code: status_code, body: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def send_invoice_xml(xml_signed_path) do
    multipart_body = [
      {"environment", "1"},
      {:file, xml_signed_path,
       {"form-data", [name: "xml_file", filename: Path.basename(xml_signed_path)]},
       [{"Content-Type", "text/plain"}]}
    ]

    case HTTPoison.post(@send_invoice_url, {:multipart, multipart_body}, @multipart_headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body, headers: headers}} ->
        {"x-sri-status", sri_status} =
          Enum.find(headers, fn {key, _value} -> key == "x-sri-status" end)

        {:ok, body: body, sri_status: sri_status}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, %{status_code: status_code, body: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def auth_invoice(access_key, environment \\ 1) do
    json_body =
      Jason.encode!(%{
        access_key: access_key,
        environment: environment
      })

    case HTTPoison.post(@auth_invoice_url, json_body, @headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body, headers: headers}} ->
        {"x-sri-status", sri_status} =
          Enum.find(headers, fn {key, _value} -> key == "x-sri-status" end)

        {:ok, body: body, sri_status: sri_status}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, %{status_code: status_code, body: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def pdf_invoice_xml(xml_signed_path) do
    multipart_body = [
      {:file, xml_signed_path,
       {"form-data", [name: "xml_file", filename: Path.basename(xml_signed_path)]},
       [{"Content-Type", "text/plain"}]}
    ]

    case HTTPoison.post(@pdf_invoice_url, {:multipart, multipart_body}, @multipart_headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, %{status_code: status_code, body: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
