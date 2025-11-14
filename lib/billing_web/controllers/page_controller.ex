defmodule BillingWeb.PageController do
  use BillingWeb, :controller

  def home(conn, _params) do
    conn
    |> put_view(BillingWeb.PageHTML)
    |> render(:home)
  end
end
