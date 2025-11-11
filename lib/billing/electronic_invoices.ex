defmodule Billing.ElectronicInvoices do
  @moduledoc false

  import Ecto.Query, warn: false
  alias Billing.Repo

  alias Billing.Quotes.ElectronicInvoice
  alias Billing.Quotes.Quote
  alias Billing.Accounts.Scope

  def create_electronic_invoice(%Scope{} = scope, %Quote{} = quote, access_key) do
    attrs = %{access_key: access_key}

    %ElectronicInvoice{quote_id: quote.id, amount: quote.amount}
    |> ElectronicInvoice.changeset(attrs, scope)
    |> Repo.insert()
  end

  def update_electronic_invoice(
        %Scope{} = scope,
        %ElectronicInvoice{} = electronic_invoice,
        state
      ) do
    true = electronic_invoice.user_id == scope.user.id

    attrs = %{state: state}

    electronic_invoice
    |> ElectronicInvoice.changeset(attrs, scope)
    |> Repo.update()
  end

  def list_electronic_invoices_by_invoice_id(%Scope{} = scope, quote_id) do
    query =
      from(ei in ElectronicInvoice,
        where: ei.quote_id == ^quote_id,
        where: ei.user_id == ^scope.user.id,
        order_by: [desc: ei.inserted_at]
      )

    Repo.all(query)
  end

  def get_electronic_invoice!(%Scope{} = scope, id) do
    Repo.get_by!(ElectronicInvoice, id: id, user_id: scope.user.id)
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

  def list_electronic_invoices(%Scope{} = scope) do
    Repo.all_by(ElectronicInvoice, user_id: scope.user.id)
  end

  def chart_data_by_month do
    current_year = DateTime.utc_now().year

    from(ei in ElectronicInvoice,
      where: ei.state == :authorized,
      where: fragment("EXTRACT(YEAR FROM ?)", ei.inserted_at) == ^current_year,
      group_by: fragment("EXTRACT(MONTH FROM ?)::integer", ei.inserted_at),
      select: %{
        month:
          selected_as(type(fragment("EXTRACT(MONTH FROM ?)", ei.inserted_at), :integer), :month),
        total: sum(ei.amount)
      },
      group_by: selected_as(:month),
      order_by: selected_as(:month)
    )
    |> Repo.all()
  end
end
