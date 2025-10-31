defmodule Billing.Invoicing do
  import Ecto.Query

  alias Billing.Quotes.Quote
  alias Billing.Repo
  alias Billing.Certificates.Certificate

  def build_request_params(%Quote{} = quote) do
    query =
      from q in Quote,
        where: q.id == ^quote.id,
        preload: [:customer, emission_profile: [:company]]

    quote = Repo.one(query)
    invoice_info = build_invoice_info(quote)
    invoice_company = build_invoice_company(quote)
    invoice_additional_info = build_invoice_additional_info(quote)
    invoice_details = build_invoice_details(quote)

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

  def fetch_certificate(quote) do
    query =
      from(c in Certificate,
        join: ep in assoc(c, :emission_profiles),
        join: i in assoc(ep, :quotes),
        where: i.id == ^quote.id
      )

    Repo.one(query)
  end

  defp build_invoice_info(quote) do
    %{
      fecha_emision: Date.to_string(quote.issued_at),
      contribuyente_especial: nil,
      dir_establecimiento: quote.emission_profile.company.address,
      identificacion_comprador: quote.customer.identification_number,
      importe_total: parse_amount(quote.amount),
      moneda: "DOLAR",
      obligado_contabilidad: "NO",
      pagos: build_payments(quote),
      propina: 0.0,
      razon_social_comprador: quote.customer.full_name,
      tipo_identificacion_comprador: fetch_customer_type(quote.customer.identification_type),
      total_con_impuestos: build_invoice_info_taxes(quote),
      total_descuento: 0.0,
      total_sin_impuestos: parse_amount(quote.amount_without_tax)
    }
  end

  defp build_payments(quote) do
    [
      %{
        total: parse_amount(quote.amount),
        forma_pago: fetch_payment_method(quote.payment_method),
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

  defp build_invoice_info_taxes(quote) do
    value =
      quote.amount
      |> Decimal.sub(quote.amount_without_tax)
      |> parse_amount()

    [
      %{
        valor: value,
        codigo: get_tax_code(:iva),
        base_imponible: parse_amount(quote.amount),
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

  defp build_invoice_company(quote) do
    %{
      ruc: quote.emission_profile.company.identification_number,
      ambiente: get_environment(),
      estab: 1,
      pto_emi: 1,
      secuencial: quote.emission_profile.sequence,
      tipo_emision: get_emission_type(),
      clave: build_access_key(quote),
      cod_doc: get_cod_doc(),
      dir_matriz: quote.emission_profile.company.address,
      nombre_comercial: quote.emission_profile.company.name,
      razon_social: quote.emission_profile.company.name
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

  defp build_access_key(quote) do
    %{
      ruc: quote.emission_profile.company.identification_number,
      ambiente: get_environment(),
      codigo: quote.id,
      estab: 1,
      fecha_emision: Date.to_string(quote.issued_at),
      pto_emi: 1,
      secuencial: quote.emission_profile.sequence,
      tipo_comprobante: get_cod_doc(),
      tipo_emision: get_emission_type()
    }
  end

  # 1: Factura

  defp get_cod_doc, do: 1

  defp build_invoice_additional_info(quote) do
    [
      %{nombre: "Dirección", valor: quote.customer.address},
      %{nombre: "Correo electrónico", valor: quote.customer.email}
    ]
  end

  defp build_invoice_details(quote) do
    value =
      quote.amount
      |> Decimal.sub(quote.amount_without_tax)
      |> parse_amount()

    [
      %{
        cantidad: 1,
        codigo_auxiliar: Integer.to_string(quote.id),
        codigo_principal: Integer.to_string(quote.id),
        descripcion: quote.description,
        descuento: 0.0,
        detalles_adicionales: [
          %{nombre: "informacionAdicional", valor: Integer.to_string(quote.id)}
        ],
        impuestos: [
          %{
            valor: value,
            codigo: get_tax_code(:iva),
            base_imponible: parse_amount(quote.amount),
            codigo_porcentaje: get_tax_percent_code(:iva),
            tarifa: parse_amount(quote.tax_rate)
          }
        ],
        precio_total_sin_impuesto: parse_amount(quote.amount_without_tax),
        precio_unitario: parse_amount(quote.amount_without_tax)
      }
    ]
  end
end
