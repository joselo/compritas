defmodule BillingWeb.LiveSessions.CartSession do
  import Phoenix.Component

  alias Billing.Accounts.User
  alias Billing.Repo
  alias Ecto.Query
  alias Billing.Accounts.Scope

  def on_mount(:mount_session, _params, %{"cart_uuid" => cart_uuid}, socket) do
    new_socket =
      socket
      |> assign_new(:cart_uuid, fn -> cart_uuid end)
      |> assign_new(:user_scope, fn -> get_user_scope() end)

    {:cont, new_socket}
  end

  defp get_user_scope do
    user =
      User
      |> Query.first()
      |> Repo.one()

    Scope.for_user(user)
  end
end
