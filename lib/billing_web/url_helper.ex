defmodule BillingWeb.URLHelper do
  alias Billing.Accounts.Scope
  alias Billing.Settings

  def add_subdomain(%Scope{} = scope, url) do
    if Billing.standalone_mode() do
      url
    else
      setting = Settings.get_setting!(scope)

      url
      |> URI.parse()
      |> Map.update!(:host, fn host -> "#{setting.subdomain}.#{host}" end)
      |> URI.to_string()
    end
  end
end
