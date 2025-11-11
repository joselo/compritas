defmodule Billing.Products do
  @moduledoc """
  The Products context.
  """

  import Ecto.Query, warn: false
  alias Billing.Repo

  alias Billing.Products.Product
  alias Billing.Accounts.Scope

  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products(scope)
      [%Product{}, ...]

  """
  def list_products(%Scope{} = scope) do
    Repo.all_by(Product, user_id: scope.user.id)
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(scope, 123)
      %Product{}

      iex> get_product!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(%Scope{} = scope, id) do
    Repo.get_by!(Product, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(scope, %{field: value})
      {:ok, %Product{}}

      iex> create_product(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(%Scope{} = scope, attrs) do
    %Product{}
    |> Product.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a product.

  ## Examples

      iex> update_product(scope, product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(scope, product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Scope{} = scope, %Product{} = product, attrs) do
    true = product.user_id == scope.user.id

    product
    |> Product.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(scope, product)
      {:ok, %Product{}}

      iex> delete_product(scope, product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Scope{} = scope, %Product{} = product) do
    true = product.user_id == scope.user.id

    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(scope, product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Scope{} = scope, %Product{} = product, attrs \\ %{}) do
    true = product.user_id == scope.user.id

    Product.changeset(product, attrs, scope)
  end
end
