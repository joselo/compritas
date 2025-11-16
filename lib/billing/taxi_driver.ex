defmodule Billing.TaxiDriver do
  alias Billing.Util.Crypto
  alias Billing.Certificates
  alias Billing.Storage
  alias Billing.Accounts.Scope

  def build_invoice_xml(invoice_params) do
    taxi_drive_adapter().build_invoice_xml(invoice_params)
  end

  def sign_invoice_xml(%Scope{} = scope, xml_path, certificate) do
    case Storage.p12_file_exists?(scope, certificate.file) do
      {:ok, p12_path} ->
        salt = Certificates.get_certificate_encryption_salt(certificate)
        opts = Certificates.get_certificate_encryption_opts()

        case Crypto.decrypt(salt, certificate.encrypted_password, opts) do
          {:ok, p12_password} ->
            taxi_drive_adapter().sign_invoice_xml(xml_path, p12_path, p12_password)

          {:error, :expired} ->
            {:error, "Contraseña del certificado expirado"}

          {:error, :invalid} ->
            {:error, "Contraseña del certificado inválida"}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def send_invoice_xml(xml_signed_path) do
    taxi_drive_adapter().send_invoice_xml(xml_signed_path)
  end

  def auth_invoice(access_key, environment \\ 1) do
    taxi_drive_adapter().auth_invoice(access_key, environment)
  end

  def pdf_invoice_xml(xml_signed_path) do
    taxi_drive_adapter().pdf_invoice_xml(xml_signed_path)
  end

  defp taxi_drive_adapter do
    Application.get_env(:billing, :taxi_drive_adapter)
  end
end
