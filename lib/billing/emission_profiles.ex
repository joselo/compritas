defmodule Billing.EmissionProfiles do
  @moduledoc """
  The EmissionProfiles context.
  """

  import Ecto.Query, warn: false
  alias Billing.Repo

  alias Billing.EmissionProfiles.EmissionProfile
  alias Billing.Accounts.Scope

  @doc """
  Returns the list of emission_profiles.

  ## Examples

      iex> list_emission_profiles(scope)
      [%EmissionProfile{}, ...]

  """
  def list_emission_profiles(%Scope{} = scope) do
    Repo.all_by(EmissionProfile, user_id: scope.user.id)
  end

  @doc """
  Gets a single emission_profile.

  Raises `Ecto.NoResultsError` if the Emission profile does not exist.

  ## Examples

      iex> get_emission_profile!(scope,  123)
      %EmissionProfile{}

      iex> get_emission_profile!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_emission_profile!(%Scope{} = scope, id) do
    Repo.get_by!(EmissionProfile, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a emission_profile.

  ## Examples

      iex> create_emission_profile(scope, %{field: value})
      {:ok, %EmissionProfile{}}

      iex> create_emission_profile(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_emission_profile(%Scope{} = scope, attrs) do
    %EmissionProfile{}
    |> EmissionProfile.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a emission_profile.

  ## Examples

      iex> update_emission_profile(scope, emission_profile, %{field: new_value})
      {:ok, %EmissionProfile{}}

      iex> update_emission_profile(scope, emission_profile, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_emission_profile(%Scope{} = scope, %EmissionProfile{} = emission_profile, attrs) do
    true = emission_profile.user_id == scope.user.id

    emission_profile
    |> EmissionProfile.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a emission_profile.

  ## Examples

      iex> delete_emission_profile(scope, emission_profile)
      {:ok, %EmissionProfile{}}

      iex> delete_emission_profile(scope, emission_profile)
      {:error, %Ecto.Changeset{}}

  """
  def delete_emission_profile(%Scope{} = scope, %EmissionProfile{} = emission_profile) do
    true = emission_profile.user_id == scope.user.id

    Repo.delete(emission_profile)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking emission_profile changes.

  ## Examples

      iex> change_emission_profile(scope, emission_profile)
      %Ecto.Changeset{data: %EmissionProfile{}}

  """
  def change_emission_profile(
        %Scope{} = scope,
        %Scope{} = scope,
        %EmissionProfile{} = emission_profile,
        attrs \\ %{}
      ) do
    true = emission_profile.user_id == scope.user.id

    EmissionProfile.changeset(emission_profile, attrs)
  end
end
