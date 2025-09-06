defmodule Billing.TaxiDriver do
  @invoice_url "https://api.taxideral.com/facturas"
  @headers [
    {"Content-Type", "application/json"},
    {"accept", "application/xml"}
  ]

  def build_invoice_xml(invoice_params) do
    json_body = Jason.encode!(%{"factura" => invoice_params})

    case HTTPoison.post(@invoice_url, json_body, @headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, %{status_code: status_code, body: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
