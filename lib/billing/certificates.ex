defmodule Billing.Certificates do
  @moduledoc """
  The Certificates context.
  """

  import Ecto.Query, warn: false
  alias Billing.Repo

  alias Billing.Certificates.Certificate
  alias Billing.Util.Crypto

  @doc """
  Returns the list of certificates.

  ## Examples

      iex> list_certificates()
      [%Certificate{}, ...]

  """
  def list_certificates do
    Repo.all(Certificate)
  end

  @doc """
  Gets a single certificate.

  Raises `Ecto.NoResultsError` if the Certificate does not exist.

  ## Examples

      iex> get_certificate!(123)
      %Certificate{}

      iex> get_certificate!(456)
      ** (Ecto.NoResultsError)

  """
  def get_certificate!(id), do: Repo.get!(Certificate, id)

  @doc """
  Creates a certificate.

  ## Examples

      iex> create_certificate(%{field: value})
      {:ok, %Certificate{}}

      iex> create_certificate(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_certificate(attrs) do
    %Certificate{}
    |> Certificate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a certificate.

  ## Examples

      iex> update_certificate(certificate, %{field: new_value})
      {:ok, %Certificate{}}

      iex> update_certificate(certificate, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_certificate(%Certificate{} = certificate, attrs) do
    certificate
    |> Certificate.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a certificate.

  ## Examples

      iex> delete_certificate(certificate)
      {:ok, %Certificate{}}

      iex> delete_certificate(certificate)
      {:error, %Ecto.Changeset{}}

  """
  def delete_certificate(%Certificate{} = certificate) do
    Repo.delete(certificate)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking certificate changes.

  ## Examples

      iex> change_certificate(certificate)
      %Ecto.Changeset{data: %Certificate{}}

  """
  def change_certificate(%Certificate{} = certificate, attrs \\ %{}) do
    Certificate.changeset(certificate, attrs)
  end

  def update_certificate_password(%Certificate{} = certificate, new_password) do
    query = from(c in Certificate, where: c.id == ^certificate.id)

    salt = get_certificate_encryption_salt(certificate)
    opts = get_certificate_encryption_opts()

    encrypted_password = Crypto.encrypt(salt, new_password, opts)

    case Repo.update_all(query, set: [encrypted_password: encrypted_password]) do
      {1, nil} -> {:ok, Repo.get(Certificate, certificate.id)}
      error -> error
    end
  end

  def get_certificate_encryption_salt(certificate) do
    "crt-#{certificate.file}"
  end

  def get_certificate_encryption_opts do
    [max_age: :infinity]
  end
end
