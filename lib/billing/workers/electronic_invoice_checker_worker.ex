defmodule Billing.ElectronicInvoiceCheckerWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Billing.InvoiceHandler

  @sleep_milliseconds 3000

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"electronic_invoice_id" => electronic_invoice_id} = _args}) do
    # Dormimos 3 segundos antes de verificar la autorizacion,
    # Ya en en entorno de pruebas el SRI suele demorar en pasar
    # un documento electronico de "Recibido" a "Autorizado"
    Process.sleep(@sleep_milliseconds)

    case InvoiceHandler.auth_electronic_invoice(electronic_invoice_id) do
      {:ok, _electronic_invoice} ->
        Logger.info("Facturado!: #{electronic_invoice_id}")

        :ok

      {:error, error} ->
        Logger.error("No se pudo verificar la autorización de la factura: #{inspect(error)}")

        {:error, error}
    end
  end
end
