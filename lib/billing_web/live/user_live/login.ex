defmodule BillingWeb.UserLive.Login do
  use BillingWeb, :live_view

  alias Billing.Accounts
  alias BillingWeb.URLHelper
  alias Billing.Accounts.Scope

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.public flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            <p>{gettext("Log in")}</p>
            <:subtitle>
              <%= if @current_scope do %>
                You need to reauthenticate to perform sensitive actions on your account.
              <% end %>
            </:subtitle>
          </.header>
        </div>

        <div :if={local_mail_adapter?()} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p>{gettext("You are running the local mail adapter.")}</p>
            <p>
              {gettext("To see sent emails, visit")} <.link href="/dev/mailbox" class="underline">{gettext("the mailbox page")}</.link>.
            </p>
          </div>
        </div>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/users/log-in"}
          phx-submit="submit_magic"
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label={gettext("Email")}
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full">
            {gettext("Log in with email")} <span aria-hidden="true">→</span>
          </.button>
        </.form>

        <div class="divider">or</div>

        <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label={gettext("Email")}
            autocomplete="username"
            required
          />
          <.input
            field={@form[:password]}
            type="password"
            label={gettext("Password")}
            autocomplete="current-password"
          />
          <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
            {gettext("Log in and stay logged in")} <span aria-hidden="true">→</span>
          </.button>
          <.button class="btn btn-primary btn-soft w-full mt-2">
            {gettext("Log in only this time")}
          </.button>
        </.form>
      </div>
    </Layouts.public>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      scope = Scope.for_user(user)

      Accounts.deliver_login_instructions(
        user,
        &URLHelper.add_subdomain(scope, url(~p"/users/log-in/#{&1}"))
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:billing, Billing.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
