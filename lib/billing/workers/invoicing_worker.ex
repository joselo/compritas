defmodule Billing.InvoicingWorker do
  use Oban.Worker, queue: :default, max_attempts: 1

  alias Billing.InvoiceHandler
  alias Billing.Accounts

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"user_id" => user_id, "electronic_invoice_id" => electronic_invoice_id} = _args
      }) do
    user = Accounts.get_user!(user_id)
    current_scope = Billing.Accounts.Scope.for_user(user)

    case InvoiceHandler.send_electronic_invoice(current_scope, electronic_invoice_id) do
      {:ok, _electronic_invoice} ->
        Logger.info("Factura enviada al SRI: #{inspect(electronic_invoice_id)}")

        :ok

      {:error, error} ->
        Logger.error("Error enviando la factura: #{inspect(error)}")

        {:error, error}
    end
  end
end
