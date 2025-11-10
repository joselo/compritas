defmodule Billing.Settings do
  @moduledoc """
  The Settings context.
  """

  import Ecto.Query, warn: false
  alias Billing.Repo

  alias Billing.Settings.Setting

  @doc """
  Gets a single setting.

  Raises `Ecto.NoResultsError` if the Setting does not exist.

  ## Examples

      iex> get_setting!()
      %Setting{}

      iex> get_setting!()
      ** (Ecto.NoResultsError)

  """
  def get_setting() do
    if setting = Setting |> first() |> Repo.one() do
      setting
    else
      %Setting{}
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
  def save_setting(%Setting{} = setting, attrs) do
    setting
    |> Setting.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking setting changes.

  ## Examples

      iex> change_setting(setting)
      %Ecto.Changeset{data: %Setting{}}

  """
  def change_setting(%Setting{} = setting, attrs \\ %{}) do
    Setting.changeset(setting, attrs)
  end
end
