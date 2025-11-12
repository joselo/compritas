defmodule BillingWeb.Plugs.SubdomainPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case String.split(conn.host, ".") do
      [subdomain, _domain, _tld] when subdomain != "" and subdomain != "www" ->
        put_session(conn, :subdomain, subdomain)

      _ ->
        conn
    end
  end
end
