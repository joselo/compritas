defmodule BillingWeb.URLHelperTest do
  use Billing.DataCase

  import Billing.AccountsFixtures, only: [user_scope_fixture: 0]
  import Billing.SettingsFixtures, only: [setting_fixture: 1]

  alias BillingWeb.URLHelper

  describe "add_subdomain/2" do
    setup do
      scope = user_scope_fixture()
      setting = setting_fixture(scope)
      url = "http://localhost:4000/users/log-in/test"

      original_value = System.get_env("STANDALONE_MODE")

      on_exit(fn ->
        if original_value do
          System.put_env("STANDALONE_MODE", original_value)
        else
          System.delete_env("STANDALONE_MODE")
        end
      end)

      {:ok, scope: scope, setting: setting, url: url}
    end

    test "add subdomain to the url without standalone mode", %{scope: scope, url: url} do
      System.put_env("STANDALONE_MODE", "true")

      assert URLHelper.add_subdomain(scope, url) == url
    end

    test "add subdomain to the url with standalone mode", %{
      scope: scope,
      setting: setting,
      url: url
    } do
      System.put_env("STANDALONE_MODE", "false")

      expected_result = "http://#{setting.subdomain}.localhost:4000/users/log-in/test"

      assert URLHelper.add_subdomain(scope, url) == expected_result
    end
  end
end
