defmodule Billing.ElectronicInvoicePdfWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Billing.InvoiceHandler

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"electronic_invoice_id" => electronic_invoice_id} = _args}) do
    case InvoiceHandler.handle_electronic_invoice_pdf(electronic_invoice_id) do
      {:ok, _electronic_invoice} ->
        Logger.info("PDF creado: #{electronic_invoice_id}")

        :ok

      {:error, error} ->
        Logger.error("No se pudo crear el PDF: #{inspect(error)}")

        {:error, error}
    end
  end
end
