defmodule Billing.Quotes do
  @moduledoc """
  The Quotes context.
  """

  import Ecto.Query, warn: false
  alias Billing.Repo

  alias Billing.Quotes.Quote
  alias Billing.Quotes.QuoteItem
  alias Ecto.Multi
  alias Billing.Accounts.Scope

  @doc """
  Returns the list of quotes.

  ## Examples

      iex> list_quotes(scope)
      [%Quote{}, ...]

  """
  def list_quotes(%Scope{} = scope) do
    query =
      from(q in Quote,
        where: q.user_id == ^scope.user.id,
        preload: [:customer],
        order_by: [desc: :inserted_at]
      )

    Repo.all(query)
  end

  @doc """
  Gets a single quote.

  Raises `Ecto.NoResultsError` if the Quote does not exist.

  ## Examples

      iex> get_quote!(scope, 123)
      %Quote{}

      iex> get_quote!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_quote!(%Scope{} = scope, id) do
    Quote
    |> Repo.get_by!(id: id, user_id: scope.user.id)
    |> Repo.preload([:customer, :items])
  end

  @doc """
  Creates a quote.

  ## Examples

      iex> create_quote(scope, quote, %{field: value})
      {:ok, %Quote{}}

      iex> create_quote(scope, quote, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_quote(%Scope{} = scope, attrs) do
    %Quote{}
    |> Quote.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a quote.

  ## Examples

      iex> update_quote(scope, quote, %{field: new_value})
      {:ok, %Quote{}}

      iex> update_quote(scope, quote, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_quote(%Scope{} = scope, %Quote{} = quote, attrs) do
    quote
    |> Quote.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a quote.

  ## Examples

      iex> delete_quote(scope, quote)
      {:ok, %Quote{}}

      iex> delete_quote(scope, quote)
      {:error, %Ecto.Changeset{}}

  """
  def delete_quote(%Scope{} = scope, %Quote{} = quote) do
    true = quote.user_id == scope.user.id

    Repo.delete(quote)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking quote changes.

  ## Examples

      iex> change_quote(quote)
      %Ecto.Changeset{data: %Quote{}}

  """
  def change_quote(%Scope{} = scope, %Quote{} = quote, attrs \\ %{}) do
    true = quote.user_id == scope.user.id

    Quote.changeset(quote, attrs, scope)
  end

  def change_quote_item(%Scope{} = scope, %QuoteItem{} = quote_item, attrs \\ %{}) do
    true = quote_item.user_id == scope.user.id

    QuoteItem.changeset(quote_item, attrs, scope)
  end

  def save_quote_amounts(%Quote{} = quote) do
    query = from qi in QuoteItem, where: qi.quote_id == ^quote.id
    items = Repo.all(query)

    multi =
      Enum.reduce(items, Multi.new(), fn item, acc ->
        divisor = Decimal.add(Decimal.new(1), Decimal.div(item.tax_rate, Decimal.new(100)))
        amount = Decimal.mult(item.price, item.quantity)
        amount_without_tax = Decimal.div(amount, divisor)

        changeset =
          Ecto.Changeset.change(item, amount: amount, amount_without_tax: amount_without_tax)

        Multi.update(acc, :"update_item_#{item.id}", changeset)
      end)
      |> Multi.run(:calculate_totals, fn _repo, changes ->
        updated_items =
          Enum.map(items, fn item ->
            case Map.get(changes, :"update_item_#{item.id}") do
              nil -> item
              updated -> updated
            end
          end)

        total_amount =
          updated_items
          |> Enum.map(& &1.amount)
          |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        total_amount_without_tax =
          updated_items
          |> Enum.map(& &1.amount_without_tax)
          |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        {:ok, {total_amount, total_amount_without_tax}}
      end)
      |> Multi.update(:update_quote, fn %{
                                          calculate_totals:
                                            {total_amount, total_amount_without_tax}
                                        } ->
        Ecto.Changeset.change(quote,
          amount: total_amount,
          amount_without_tax: total_amount_without_tax
        )
      end)

    Repo.transaction(multi)
  end
end
