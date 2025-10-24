defmodule Billing.InvoicingWorker do
  use Oban.Worker, queue: :default, max_attempts: 1

  alias Billing.InvoiceHandler

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"electronic_invoice_id" => electronic_invoice_id} = _args}) do
    case InvoiceHandler.handle_electronic_invoice(electronic_invoice_id) do
      {:ok, _electronic_invoice} ->
        Logger.info("Factura enviada al SRI: #{inspect(electronic_invoice_id)}")

        :ok

      {:error, error} ->
        Logger.error("Error enviando la factura: #{inspect(error)}")

        {:error, error}
    end
  end
end
