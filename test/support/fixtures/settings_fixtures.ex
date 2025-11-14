defmodule Billing.SettingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Billing.Settings` context.
  """

  @doc """
  Generate a setting.
  """
  def setting_fixture(scope, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        title: "My Store"
      })

    setting = %Billing.Settings.Setting{user_id: scope.user.id}

    {:ok, setting} = Billing.Settings.save_setting(scope, setting, attrs)

    setting
  end
end
