defmodule Billing.Orders do
  @moduledoc """
  The Orders context.
  """

  import Ecto.Query, warn: false

  alias Billing.Repo
  alias Billing.Orders.Order
  alias Billing.Orders.OrderItem
  alias Ecto.Multi
  alias Billing.Accounts.Scope

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders(scope)
      [%Order{}, ...]

  """
  def list_orders(%Scope{} = scope) do
    Repo.all_by(Certificate, user_id: scope.user.id)
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(scope, 123)
      %Order{}

      iex> get_order!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(%Scope{} = scope, id) do
    Repo.get_by!(Order, id: id, user_id: scope.user.id) |> Repo.preload(:items)
  end

  @doc """
  Creates a order.

  ## Examples

      iex> create_order(scope, %{field: value})
      {:ok, %Order{}}

      iex> create_order(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(%Scope{} = scope, attrs) do
    %Order{}
    |> Order.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a order.

  ## Examples

      iex> update_order(scope, order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(scope, order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Scope{} = scope, %Order{} = order, attrs) do
    true = order.user_id == scope.user.id

    order
    |> Order.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a order.

  ## Examples

      iex> delete_order(scope, order)
      {:ok, %Order{}}

      iex> delete_order(scope, order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order(%Scope{} = scope, %Order{} = order) do
    true = order.user_id == scope.user.id

    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(scope, order)
      %Ecto.Changeset{data: %Order{}}

  """
  def change_order(%Scope{} = scope, %Order{} = order, attrs \\ %{}) do
    true = order.user_id == scope.user.id

    Order.changeset(order, attrs)
  end

  def save_order_amounts(%Order{} = order) do
    query = from oi in OrderItem, where: oi.order_id == ^order.id
    items = Repo.all(query)

    multi =
      Enum.reduce(items, Multi.new(), fn item, acc ->
        amount = Decimal.mult(item.price, item.quantity)

        changeset = Ecto.Changeset.change(item, amount: amount)
        Multi.update(acc, :"update_item_#{item.id}", changeset)
      end)
      |> Multi.run(:calculate_amounts, fn _repo, changes ->
        updated_items =
          Enum.map(items, fn item ->
            case Map.get(changes, :"update_item_#{item.id}") do
              nil -> item
              updated -> updated
            end
          end)

        amount =
          updated_items
          |> Enum.map(& &1.amount)
          |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

        {:ok, amount}
      end)
      |> Multi.update(:update_order, fn %{
                                          calculate_amounts: amount
                                        } ->
        Ecto.Changeset.change(order,
          amount: amount
        )
      end)

    Repo.transaction(multi)
  end
end
