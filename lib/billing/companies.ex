defmodule Billing.Companies do
  @moduledoc """
  The Companies context.
  """

  import Ecto.Query, warn: false
  alias Billing.Repo

  alias Billing.Companies.Company
  alias Billing.Accounts.Scope

  @doc """
  Returns the list of companies.

  ## Examples

      iex> list_companies(scope)
      [%Company{}, ...]

  """
  def list_companies(%Scope{} = scope) do
    Repo.all_by(Company, user_id: scope.user.id)
  end

  @doc """
  Gets a single company.

  Raises `Ecto.NoResultsError` if the Company does not exist.

  ## Examples

      iex> get_company!(scope, 123)
      %Company{}

      iex> get_company!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_company!(%Scope{} = scope, id) do
    Repo.get_by!(Company, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a company.

  ## Examples

      iex> create_company(scope, %{field: value})
      {:ok, %Company{}}

      iex> create_company(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_company(%Scope{} = scope, attrs) do
    %Company{}
    |> Company.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a company.

  ## Examples

      iex> update_company(scope, company, %{field: new_value})
      {:ok, %Company{}}

      iex> update_company(scope, company, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_company(%Scope{} = scope, %Company{} = company, attrs) do
    true = company.user_id == scope.user.id

    company
    |> Company.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a company.

  ## Examples

      iex> delete_company(scope, company)
      {:ok, %Company{}}

      iex> delete_company(scope, company)
      {:error, %Ecto.Changeset{}}

  """
  def delete_company(%Scope{} = scope, %Company{} = company) do
    true = company.user_id == scope.user.id

    Repo.delete(company)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking company changes.

  ## Examples

      iex> change_company(scope, company)
      %Ecto.Changeset{data: %Company{}}

  """
  def change_company(%Scope{} = scope, %Company{} = company, attrs \\ %{}) do
    true = company.user_id == scope.user.id

    Company.changeset(company, attrs, scope)
  end
end
