defmodule BillingWeb.ElectronicInvoiceController do
  use BillingWeb, :controller

  alias Billing.ElectronicInvoices
  alias Billing.InvoiceHandler

  def pdf(conn, %{"id" => id}) do
    electronic_invoice =
      ElectronicInvoices.get_electronic_invoice!(conn.assigns.current_scope, id)

    pdf =
      electronic_invoice.access_key
      |> InvoiceHandler.pdf_path()
      |> File.read!()

    conn
    |> put_resp_content_type("application/pdf")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"#{electronic_invoice.access_key}.pdf\""
    )
    |> send_resp(200, pdf)
  end

  def xml(conn, %{"id" => id}) do
    electronic_invoice =
      ElectronicInvoices.get_electronic_invoice!(conn.assigns.current_scope, id)

    xml =
      electronic_invoice.access_key
      |> InvoiceHandler.xml_auth_path()
      |> File.read!()

    conn
    |> put_resp_content_type("application/xml")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"#{electronic_invoice.access_key}.xml\""
    )
    |> send_resp(200, xml)
  end
end
