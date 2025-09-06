defmodule Billing.InvoicingTest do
  use Billing.DataCase

  import Billing.InvoicesFixtures
  import Billing.CustomersFixtures
  import Billing.EmissionProfilesFixtures
  import Billing.CompaniesFixtures
  import Billing.CertificatesFixtures

  setup do
    customer =
      customer_fixture(%{
        full_name: "Henry Case",
        email: "cliente@ejemplo.com",
        identification_number: "1713328506",
        identification_type: "cedula",
        address: "Ciudadela: XYZ Calle: XYZ Número: XYZ Intersección: XYZ",
        phone_number: "1234567890"
      })

    company =
      company_fixture(%{
        identification_number: "1792146739001",
        address: "Ciudadela: XYZ Calle: XYZ Número: XYZ Intersección: XYZ",
        name: "Henry Case"
      })

    certificate =
      certificate_fixture(%{
        name: "Certificate Name",
        file: "certificate_file.p12",
        password: "certificate_password"
      })

    emission_profile =
      emission_profile_fixture(%{
        company_id: company.id,
        certificate_id: certificate.id,
        name: "Emission Profile Name"
      })

    invoice =
      invoice_fixture(%{
        customer_id: customer.id,
        emission_profile_id: emission_profile.id,
        issued_at: ~D[2025-08-21],
        description: "Invoice Description",
        due_date: ~D[2025-09-21],
        amount: 24.75,
        tax_rate: 15.0,
        payment_method: "cash"
      })

    amount_with_tax = Billing.Invoices.calculate_amount_with_tax(invoice)
    Billing.Invoices.save_taxes(invoice, amount_with_tax)

    {:ok, invoice: invoice}
  end

  describe "build_request_params" do
    test "creates invoice request params", %{invoice: invoice} do
      params = Billing.Invoicing.build_request_params(invoice)

      assert params[:info_factura] == %{
               fecha_emision: "2025-08-21",
               contribuyente_especial: nil,
               dir_establecimiento: "Ciudadela: XYZ Calle: XYZ Número: XYZ Intersección: XYZ",
               identificacion_comprador: "1713328506",
               importe_total: 28.46,
               moneda: "DOLAR",
               obligado_contabilidad: "NO",
               pagos: [
                 %{total: 28.46, forma_pago: 1, plazo: 0, unidad_tiempo: "Dias"}
               ],
               propina: 0.0,
               razon_social_comprador: "Henry Case",
               tipo_identificacion_comprador: 5,
               total_con_impuestos: [
                 %{
                   valor: 3.71,
                   codigo: 2,
                   base_imponible: 24.75,
                   codigo_porcentaje: 4,
                   descuentoAdicional: 0.0
                 },
                 %{
                   valor: 0.0,
                   codigo: 2,
                   base_imponible: 0.0,
                   codigo_porcentaje: 0,
                   descuentoAdicional: 0.0
                 }
               ],
               total_descuento: 0.0,
               total_sin_impuestos: 24.75
             }

      assert params[:info_tributaria] == %{
               ruc: "1792146739001",
               ambiente: 1,
               estab: 1,
               pto_emi: 1,
               secuencial: 109,
               tipo_emision: 1,
               clave: %{
                 ruc: "1792146739001",
                 ambiente: 1,
                 codigo: invoice.id,
                 estab: 1,
                 fecha_emision: "2025-08-21",
                 pto_emi: 1,
                 secuencial: 109,
                 tipo_comprobante: 1,
                 tipo_emision: 1
               },
               cod_doc: 1,
               dir_matriz: "Ciudadela: XYZ Calle: XYZ Número: XYZ Intersección: XYZ",
               nombre_comercial: "Henry Case",
               razon_social: "Henry Case"
             }

      assert params[:info_adicional] == [
               %{
                 nombre: "Dirección",
                 valor: "Ciudadela: XYZ Calle: XYZ Número: XYZ Intersección: XYZ"
               },
               %{nombre: "Correo electrónico", valor: "cliente@ejemplo.com"}
             ]

      assert params[:detalles] == [
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
                     valor: 3.71,
                     codigo: 2,
                     base_imponible: 24.75,
                     codigo_porcentaje: 4,
                     tarifa: 15.0
                   }
                 ],
                 precio_total_sin_impuesto: 24.75,
                 precio_unitario: 24.75
               }
             ]
    end
  end
end
