defmodule BillingWeb.LiveSessions.StoreSession do
  import Phoenix.Component
  import Ecto.Query, warn: false

  alias Billing.Accounts.User
  alias Billing.Settings.Setting
  alias Billing.Repo
  alias Billing.Accounts.Scope

  defmodule StoreNotFoundError do
    use Gettext, backend: BillingWeb.Gettext

    defexception message: gettext("Store not available"), plug_status: 404
  end

  def on_mount(:mount_store_scope, _params, %{"cart_uuid" => cart_uuid} = session, socket) do
    socket
    |> assign_new(:cart_uuid, fn -> cart_uuid end)
    |> assign_new(:store_scope, fn -> get_store_scope(session["subdomain"]) end)
    |> handle_store_scope()
  end

  defp get_store_scope(nil) do
    user =
      User
      |> first()
      |> Repo.one()

    Scope.for_user(user)
  end

  defp get_store_scope(subdomain) do
    query =
      from(u in User,
        join: s in Setting,
        on: u.id == s.user_id,
        where: s.subdomain == ^subdomain
      )

    user = Repo.one(query)

    Scope.for_user(user)
  end

  def handle_store_scope(%{assigns: %{store_scope: %Scope{user: %User{}}}} = socket) do
    {:cont, socket}
  end

  def handle_store_scope(_socket) do
    raise StoreNotFoundError
  end
end
