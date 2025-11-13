defmodule BillingWeb.Plugs.SetupGatePlug do
  use BillingWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Billing.Accounts.User
  alias Billing.Repo

  @register_path ["users", "register"]

  def init(_) do
  end

  def call(%{path_info: @register_path} = conn, _params) do
    if Billing.standalone_mode() do
      if user_exists?() do
        conn
        |> redirect(to: ~p"/")
        |> halt()
      else
        conn
      end
    else
      conn
    end
  end

  def call(%{path_info: _path_info} = conn, _params) do
    if Billing.standalone_mode() do
      if user_exists?() do
        conn
      else
        conn
        |> redirect(to: ~p"/users/register")
        |> halt()
      end
    else
      conn
    end
  end

  defp user_exists? do
    if Mix.env() == :test do
      Repo.exists?(User)
    else
      case Process.get(:setup_gate_user_exists) do
        nil ->
          exists = Repo.exists?(User)
          Process.put(:setup_gate_user_exists, exists)
          exists

        cached ->
          cached
      end
    end
  end
end
