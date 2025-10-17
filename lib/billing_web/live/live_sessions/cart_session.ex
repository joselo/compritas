defmodule BillingWeb.LiveSessions.CartSession do
  import Phoenix.Component

  def on_mount(:mount_session, _params, %{"cart_uuid" => cart_uuid}, socket) do
    {:cont, assign_new(socket, :cart_uuid, fn -> cart_uuid end)}
  end
end
