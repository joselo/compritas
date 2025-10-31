defmodule Billing.TaxiDriverTest do
  use ExUnit.Case

  # describe "build_invoice_xml/1" do
  #   test "call to the Taxideral api to build an xml quote" do
  #     response = Billing.TaxiDriver.build_invoice_xml(fake_invoice_params())
  #
  #     IO.puts (response)
  #   end
  # end

  defp fake_invoice_params do
    %{
      info_factura: %{
        fecha_emision: "2025-08-21",
        contribuyente_especial: nil,
        dir_establecimiento: "Ciudadela: XYZ Calle: XYZ Número: XYZ Intersección: XYZ",
        identificacion_comprador: "1713328506",
        importe_total: 28.46,
        moneda: "DOLAR",
        obligado_contabilidad: "NO",
        pagos: [%{total: 28.46, forma_pago: 1, plazo: 0, unidad_tiempo: "Dias"}],
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
      },
      info_tributaria: %{
        ruc: "1792146739001",
        ambiente: 1,
        estab: 1,
        pto_emi: 1,
        secuencial: 109,
        tipo_emision: 1,
        clave: %{
          fecha_emision: "2025-08-21",
          codigo: 72,
          ruc: "1792146739001",
          ambiente: 1,
          estab: 1,
          pto_emi: 1,
          secuencial: 109,
          tipo_emision: 1,
          tipo_comprobante: 1
        },
        cod_doc: 1,
        dir_matriz: "Ciudadela: XYZ Calle: XYZ Número: XYZ Intersección: XYZ",
        nombre_comercial: "Henry Case",
        razon_social: "Henry Case"
      },
      info_adicional: [
        %{
          valor: "Ciudadela: XYZ Calle: XYZ Número: XYZ Intersección: XYZ",
          nombre: "Dirección"
        },
        %{valor: "cliente@ejemplo.com", nombre: "Correo electrónico"}
      ],
      detalles: [
        %{
          cantidad: 1,
          codigo_auxiliar: "72",
          codigo_principal: "72",
          descripcion: "Invoice Description",
          descuento: 0.0,
          detalles_adicionales: [%{valor: "72", nombre: "informacionAdicional"}],
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
    }
  end
end
