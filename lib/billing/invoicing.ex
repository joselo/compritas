defmodule Billing.Invoicing do
  import Ecto.Query

  alias Billing.Invoices.Invoice
  alias Billing.Repo

  def build_request_params(%Invoice{} = invoice) do
    query =
      from i in Invoice,
        where: i.id == ^invoice.id,
        preload: [:customer, emission_profile: [:company]]

    invoice = Repo.one(query)
    invoice_info = build_invoice_info(invoice)

    %{
      invoice_info: invoice_info
    }
  end

  defp build_invoice_info(invoice) do
    %{
      fecha_emision: Date.to_string(invoice.issued_at),
      contribuyente_especial: nil,
      dir_establecimiento: invoice.emission_profile.company.address,
      identificacion_comprador: invoice.customer.identification_number,
      importe_total: Decimal.to_string(invoice.amount_with_tax),
      moneda: "DOLAR",
      obligado_contabilidad: "NO",
      pagos: build_payments(invoice),
      propina: 0.0,
      razon_social_comprador: invoice.emission_profile.company.name,
      tipo_identificacion_comprador: fetch_customer_type(invoice.customer.identification_type)
    }
  end

  defp build_payments(invoice) do
    [
      %{
        total: Decimal.to_string(invoice.amount_with_tax),
        forma_pago: fetch_payment_method(invoice.payment_method),
        plazo: 0,
        unidad_tiempo: "Dias"
      }
    ]
  end

  defp fetch_customer_type(customer_type) do
    case customer_type do
      :cedula -> "5"
      :ruc -> "4"
    end
  end

  defp fetch_payment_method(payment_method) do
    case payment_method do
      :cash -> "1"
      :credit_card -> "19"
      :bank_transfer -> "20"
    end
  end
end
