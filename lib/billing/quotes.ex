defmodule Billing.Quotes do
  @moduledoc """
  The Quotes context.
  """

  import Ecto.Query, warn: false
  alias Billing.Repo

  alias Billing.Quotes.Quote
  alias Billing.Quotes.QuoteItem
  alias Ecto.Multi

  @doc """
  Returns the list of quotes.

  ## Examples

      iex> list_quotes()
      [%Quote{}, ...]

  """
  def list_quotes do
    query = from(i in Quote, preload: [:customer], order_by: [desc: :inserted_at])

    Repo.all(query)
  end

  @doc """
  Gets a single quote.

  Raises `Ecto.NoResultsError` if the Quote does not exist.

  ## Examples

      iex> get_quote!(123)
      %Quote{}

      iex> get_quote!(456)
      ** (Ecto.NoResultsError)

  """
  def get_quote!(id), do: Repo.get!(Quote, id) |> Repo.preload([:customer, :items])

  @doc """
  Creates a quote.

  ## Examples

      iex> create_quote(%{field: value})
      {:ok, %Quote{}}

      iex> create_quote(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_quote(attrs) do
    %Quote{}
    |> Quote.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a quote.

  ## Examples

      iex> update_quote(quote, %{field: new_value})
      {:ok, %Quote{}}

      iex> update_quote(quote, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_quote(%Quote{} = quote, attrs) do
    quote
    |> Quote.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a quote.

  ## Examples

      iex> delete_quote(quote)
      {:ok, %Quote{}}

      iex> delete_quote(quote)
      {:error, %Ecto.Changeset{}}

  """
  def delete_quote(%Quote{} = quote) do
    Repo.delete(quote)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking quote changes.

  ## Examples

      iex> change_quote(quote)
      %Ecto.Changeset{data: %Quote{}}

  """
  def change_quote(%Quote{} = quote, attrs \\ %{}) do
    Quote.changeset(quote, attrs)
  end

  def change_quote_item(%QuoteItem{} = quote_item, attrs \\ %{}) do
    QuoteItem.changeset(quote_item, attrs)
  end

  def save_quote_item_amounts(%Quote{} = quote) do
    query = from qi in QuoteItem, where: qi.quote_id == ^quote.id
    items = Repo.all(query)

    multi =
      Enum.reduce(items, Multi.new(), fn item, acc ->
        divisor = Decimal.add(Decimal.new(1), Decimal.div(item.tax_rate, Decimal.new(100)))
        amount_without_tax = Decimal.div(item.amount, divisor)

        changeset = Ecto.Changeset.change(item, amount_without_tax: amount_without_tax)
        Multi.update(acc, :"update_#{item.id}", changeset)
      end)

    Repo.transaction(multi)
  end
end
