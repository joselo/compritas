defmodule Billing.ElectronicInvoices do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Billing.Repo

  alias Billing.Quotes.ElectronicInvoice

  def create_electronic_invoice(quote_id, access_key) do
    attrs = %{quote_id: quote_id, access_key: access_key}

    %ElectronicInvoice{}
    |> ElectronicInvoice.changeset(attrs)
    |> Repo.insert()
  end

  def update_electronic_invoice(%ElectronicInvoice{} = electronic_invoice, state) do
    attrs = %{state: state}

    electronic_invoice
    |> ElectronicInvoice.changeset(attrs)
    |> Repo.update()
  end

  def list_electronic_invoices_by_invoice_id(quote_id) do
    query =
      from(ei in ElectronicInvoice,
        where: ei.quote_id == ^quote_id,
        order_by: [desc: ei.inserted_at]
      )

    Repo.all(query)
  end

  def get_electronic_invoice!(id) do
    Repo.get!(ElectronicInvoice, id)
  end

  def list_pending_electronic_invoices do
    pending_states = [
      :signed,
      :sent,
      :not_found_or_pending
    ]

    query = from(ei in ElectronicInvoice, where: ei.state in ^pending_states)

    Repo.all(query)
  end

  def list_electronic_invoices do
    ElectronicInvoice
    |> Repo.all()
    |> Repo.preload(quote: :customer)
  end
end
