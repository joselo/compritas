defmodule BillingWeb.PageControllerTest do
  use BillingWeb.ConnCase

  import Billing.AccountsFixtures

  test "GET /", %{conn: conn} do
    _user = user_fixture()

    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Catalog"
  end
end
