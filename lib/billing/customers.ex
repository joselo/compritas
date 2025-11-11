defmodule Billing.Customers do
  @moduledoc """
  The Customers context.
  """

  import Ecto.Query, warn: false
  alias Billing.Repo

  alias Billing.Customers.Customer
  alias Billing.Accounts.Scope

  @doc """
  Returns the list of customers.

  ## Examples

      iex> list_customers(scope)
      [%Customer{}, ...]

  """
  def list_customers(%Scope{} = scope) do
    Repo.all_by(Customer, user_id: scope.user.id)
  end

  @doc """
  Gets a single customer.

  Raises `Ecto.NoResultsError` if the Customer does not exist.

  ## Examples

      iex> get_customer!(scope, 123)
      %Customer{}

      iex> get_customer!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_customer!(%Scope{} = scope, id) do
    Repo.get_by!(Customer, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a customer.

  ## Examples

      iex> create_customer(scope, %{field: value})
      {:ok, %Customer{}}

      iex> create_customer(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_customer(%Scope{} = scope, attrs) do
    %Customer{}
    |> Customer.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a customer.

  ## Examples

      iex> update_customer(scope, customer, %{field: new_value})
      {:ok, %Customer{}}

      iex> update_customer(scope, customer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_customer(%Scope{} = scope, %Customer{} = customer, attrs) do
    true = customer.user_id == scope.user.id

    customer
    |> Customer.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a customer.

  ## Examples

      iex> delete_customer(scope, customer)
      {:ok, %Customer{}}

      iex> delete_customer(scope, customer)
      {:error, %Ecto.Changeset{}}

  """
  def delete_customer(%Scope{} = scope, %Customer{} = customer) do
    true = customer.user_id == scope.user.id

    Repo.delete(customer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> change_customer(scope, customer)
      %Ecto.Changeset{data: %Customer{}}

  """
  def change_customer(%Scope{} = scope, %Customer{} = customer, attrs \\ %{}) do
    true = customer.user_id == scope.user.id

    Customer.changeset(customer, attrs, scope)
  end

  def find_or_create_customer(
        %Scope{} = scope,
        %{identification_number: identification_number} = attrs
      ) do
    if user = Repo.get_by(Customer, %{identification_number: identification_number}) do
      {:ok, user}
    else
      create_customer(scope, attrs)
    end
  end
end
