defmodule BillingWeb.Plugs.SubdomainPlug do
  import Plug.Conn

  @register_path ["users", "register"]
  @ignored_subdomains ~w(www)

  def init(opts), do: opts

  def call(conn, _opts) do
    if Billing.standalone_mode() do
      conn
    else
      case String.split(conn.host, ".") do
        [subdomain, _domain, _tld]
        when subdomain != "" and subdomain not in @ignored_subdomains ->
          put_session(conn, :subdomain, subdomain)

        _ ->
          if conn.path_info == @register_path do
            conn
          else
            conn
            |> put_status(404)
            |> put_resp_content_type("text/plain")
            |> send_resp(404, "Subdomain is required to access this page")
            |> halt()
          end
      end
    end
  end
end
