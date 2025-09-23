defmodule Billing.Invoicing do
  import Ecto.Query

  alias Billing.Invoices.Invoice
  alias Billing.Repo
  alias Billing.Certificates.Certificate

  @secuencial 543

  def build_request_params(%Invoice{} = invoice) do
    query =
      from i in Invoice,
        where: i.id == ^invoice.id,
        preload: [:customer, emission_profile: [:company]]

    invoice = Repo.one(query)
    invoice_info = build_invoice_info(invoice)
    invoice_company = build_invoice_company(invoice)
    invoice_additional_info = build_invoice_additional_info(invoice)
    invoice_details = build_invoice_details(invoice)

    invoice_params = %{
      factura: %{
        info_factura: invoice_info,
        info_tributaria: invoice_company,
        info_adicional: invoice_additional_info,
        detalles: invoice_details
      }
    }

    {:ok, invoice_params}
  end

  def fetch_certificate(invoice) do
    query =
      from(c in Certificate,
        join: ep in assoc(c, :emission_profiles),
        join: i in assoc(ep, :invoices),
        where: i.id == ^invoice.id
      )

    Repo.one(query)
  end

  defp build_invoice_info(invoice) do
    %{
      fecha_emision: Date.to_string(invoice.issued_at),
      contribuyente_especial: nil,
      dir_establecimiento: invoice.emission_profile.company.address,
      identificacion_comprador: invoice.customer.identification_number,
      importe_total: parse_amount(invoice.amount_with_tax),
      moneda: "DOLAR",
      obligado_contabilidad: "NO",
      pagos: build_payments(invoice),
      propina: 0.0,
      razon_social_comprador: invoice.customer.full_name,
      tipo_identificacion_comprador: fetch_customer_type(invoice.customer.identification_type),
      total_con_impuestos: build_invoice_info_taxes(invoice),
      total_descuento: 0.0,
      total_sin_impuestos: parse_amount(invoice.amount)
    }
  end

  defp build_payments(invoice) do
    [
      %{
        total: parse_amount(invoice.amount_with_tax),
        forma_pago: fetch_payment_method(invoice.payment_method),
        plazo: 0,
        unidad_tiempo: "Dias"
      }
    ]
  end

  defp fetch_customer_type(customer_type) do
    case customer_type do
      :cedula -> 5
      :ruc -> 4
    end
  end

  defp fetch_payment_method(payment_method) do
    case payment_method do
      :cash -> 1
      :credit_card -> 19
      :bank_transfer -> 20
    end
  end

  defp build_invoice_info_taxes(invoice) do
    value =
      invoice.amount_with_tax
      |> Decimal.sub(invoice.amount)
      |> parse_amount()

    [
      %{
        valor: value,
        codigo: get_tax_code(:iva),
        base_imponible: parse_amount(invoice.amount),
        codigo_porcentaje: get_tax_percent_code(:iva),
        descuentoAdicional: 0.0
      },
      %{
        valor: 0.0,
        codigo: get_tax_code(:iva),
        base_imponible: 0.0,
        codigo_porcentaje: get_tax_percent_code(:no_iva),
        descuentoAdicional: 0.0
      }
    ]
  end

  # IVA: 2
  # ICE: 3
  # IRBPNR: 5
  defp get_tax_code(:iva), do: 2
  defp get_tax_code(_), do: 0

  # 0%: 0
  # 12%: 2
  # 14%: 3
  # 15%: 4
  # No objeto de impuesto: 6
  # Excento de Iva: 7

  defp get_tax_percent_code(:iva), do: 4
  defp get_tax_percent_code(_), do: 0

  defp parse_amount(%Decimal{} = amount) do
    Decimal.round(amount, 2) |> Decimal.to_float()
  end

  defp build_invoice_company(invoice) do
    %{
      ruc: invoice.emission_profile.company.identification_number,
      ambiente: get_environment(),
      estab: 1,
      pto_emi: 1,
      secuencial: @secuencial,
      tipo_emision: get_emission_type(),
      clave: build_access_key(invoice),
      cod_doc: get_cod_doc(),
      dir_matriz: invoice.emission_profile.company.address,
      nombre_comercial: invoice.emission_profile.company.name,
      razon_social: invoice.emission_profile.company.name
    }
  end

  # 1: Pruebas
  # 2: Producción

  defp get_environment() do
    1
  end

  # 1: Normal

  defp get_emission_type() do
    1
  end

  defp build_access_key(invoice) do
    %{
      ruc: invoice.emission_profile.company.identification_number,
      ambiente: get_environment(),
      codigo: invoice.id,
      estab: 1,
      fecha_emision: Date.to_string(invoice.issued_at),
      pto_emi: 1,
      secuencial: @secuencial,
      tipo_comprobante: get_cod_doc(),
      tipo_emision: get_emission_type()
    }
  end

  # 1: Factura

  defp get_cod_doc, do: 1

  defp build_invoice_additional_info(invoice) do
    [
      %{nombre: "Dirección", valor: invoice.customer.address},
      %{nombre: "Correo electrónico", valor: invoice.customer.email}
    ]
  end

  defp build_invoice_details(invoice) do
    value =
      invoice.amount_with_tax
      |> Decimal.sub(invoice.amount)
      |> parse_amount()

    [
      %{
        cantidad: 1,
        codigo_auxiliar: Integer.to_string(invoice.id),
        codigo_principal: Integer.to_string(invoice.id),
        descripcion: invoice.description,
        descuento: 0.0,
        detalles_adicionales: [
          %{nombre: "informacionAdicional", valor: Integer.to_string(invoice.id)}
        ],
        impuestos: [
          %{
            valor: value,
            codigo: get_tax_code(:iva),
            base_imponible: parse_amount(invoice.amount),
            codigo_porcentaje: get_tax_percent_code(:iva),
            tarifa: parse_amount(invoice.tax_rate)
          }
        ],
        precio_total_sin_impuesto: parse_amount(invoice.amount),
        precio_unitario: parse_amount(invoice.amount)
      }
    ]
  end
end
