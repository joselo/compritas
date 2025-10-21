defmodule BillingWeb.Plugs.SetupPlug do
  use BillingWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Billing.Accounts.User
  alias Billing.Repo

  def init(_) do
  end

  def call(conn, _params) do
    if Repo.exists?(User) do
      conn
      |> redirect(to: ~p"/")
      |> halt()
    else
      conn
    end
  end
end
