defmodule BillingWeb.Plugs.SubdomainPlug do
  import Plug.Conn

  alias BillingWeb.PageController

  @register_path ["users", "register"]
  @ignored_subdomains ~w(www)

  def init(opts), do: opts

  def call(conn, _opts) do
    if Billing.allow_registration() do
      case String.split(conn.host, ".") do
        [subdomain, _domain, _tld]
        when subdomain != "" and subdomain not in @ignored_subdomains ->
          put_session(conn, :subdomain, subdomain)

        _ ->
          if conn.path_info == @register_path do
            conn
          else
            conn
            |> PageController.home(%{})
            |> halt()
          end
      end
    else
      conn
    end
  end
end
