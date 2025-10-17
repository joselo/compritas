defmodule BillingWeb.Plugs.CartPlug do
  import Plug.Conn

  def init(_) do
  end

  def call(conn, _params) do
    cart_uuid = get_session(conn, :cart_uuid) || Ecto.UUID.generate()

    put_session(conn, :cart_uuid, cart_uuid)
  end
end
