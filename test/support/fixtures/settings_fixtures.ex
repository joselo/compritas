defmodule Billing.SettingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Billing.Settings` context.
  """

  @doc """
  Generate a setting.
  """
  def setting_fixture(scope, attrs \\ %{}) do
    {:ok, subdomain} = Billing.Subdomains.generate_unique_subdomain()

    attrs =
      attrs
      |> Enum.into(%{
        title: "My Store",
        subdomain: subdomain
      })

    setting = %Billing.Settings.Setting{user_id: scope.user.id, subdomain: subdomain}

    {:ok, setting} = Billing.Settings.save_setting(scope, setting, attrs)

    setting
  end
end
