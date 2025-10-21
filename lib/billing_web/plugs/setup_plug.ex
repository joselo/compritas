defmodule BillingWeb.Plugs.SetupGatePlug do
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
    else
      conn
      |> redirect(to: ~p"/users/register")
      |> halt()
    end
  end
end
