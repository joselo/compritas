defmodule Billing.Settings do
  @moduledoc """
  The Settings context.
  """

  import Ecto.Query, warn: false
  alias Billing.Repo

  alias Billing.Settings.Setting
  alias Billing.Accounts.Scope

  @doc """
  Gets a single setting.

  Raises `Ecto.NoResultsError` if the Setting does not exist.

  ## Examples

      iex> get_setting!(scope)
      %Setting{}

      iex> get_setting!(scope)
      ** (Ecto.NoResultsError)

  """
  def get_setting(%Scope{} = scope) do
    if setting = Repo.get_by(Setting, user_id: scope.user.id) do
      setting
    else
      %Setting{user_id: scope.user.id}
    end
  end

  @doc """
  Creates a setting.

  ## Examples

      iex> save_settings(%{field: value})
      {:ok, %Setting{}}

      iex> save_settings(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def save_setting(%Scope{} = scope, %Setting{} = setting, attrs) do
    setting
    |> Setting.changeset(attrs, scope)
    |> Repo.insert_or_update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking setting changes.

  ## Examples

      iex> change_setting(scope, setting)
      %Ecto.Changeset{data: %Setting{}}

  """
  def change_setting(%Scope{} = scope, %Setting{} = setting, attrs \\ %{}) do
    Setting.changeset(setting, attrs, scope)
  end
end
