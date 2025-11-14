defmodule Billing.ElectronicInvoiceErrors do
  import SweetXml

  alias Billing.Quotes.ElectronicInvoice
  alias Billing.InvoiceHandler
  alias Billing.Accounts.Scope

  @errors [
    identificador: "Identificador",
    informacionAdicional: "Información adicional",
    mensaje: "Mensaje",
    tipo: "Tipo"
  ]

  def list_errors(%Scope{} = scope, %ElectronicInvoice{state: state, access_key: access_key})
      when state in [:back, :error] do
    scope
    |> InvoiceHandler.xml_response_path(access_key)
    |> File.read!()
    |> parse_xml_errors()
    |> format_errors()
  end

  def list_errors(%Scope{} = scope, %ElectronicInvoice{state: state, access_key: access_key})
      when state in [:unauthorized] do
    scope
    |> InvoiceHandler.xml_auth_path(access_key)
    |> File.read!()
    |> parse_xml_errors()
    |> format_errors()
  end

  def list_errors(_electronic_invoice) do
    []
  end

  defp parse_xml_errors(xml) do
    if xml && String.trim(xml) != "" && well_formed?(xml) do
      message_node = xpath(xml, errors_xpath())

      if message_node do
        xml
        |> xpath(~x"//mensaje",
          identificador: ~x"./identificador/text()",
          informacionAdicional: ~x"./informacionAdicional/text()",
          mensaje: ~x"./mensaje/text()",
          tipo: ~x"./tipo/text()"
        )
        |> Enum.map(&format_attribute(&1))
      end
    end
  end

  defp format_attribute({key, nil}) do
    {key, nil}
  end

  defp format_attribute({key, value}) do
    {key, to_string(value)}
  end

  defp well_formed?(xml) do
    xpath(xml, errors_xpath())
  catch
    :exit, _ -> false
  end

  defp errors_xpath do
    ~x"//mensaje"
  end

  defp format_errors(errors) do
    Enum.map(errors, fn {key, value} ->
      {@errors[key], value}
    end)
  end
end
