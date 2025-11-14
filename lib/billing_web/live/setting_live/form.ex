defmodule BillingWeb.SettingLive.Form do
  use BillingWeb, :live_view

  alias Billing.Settings

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="text-center">
        <.header>
          {gettext("Store Setttings")}
          <:subtitle>
            {gettext("ustomize your store, change the store name or upload a logo")}
          </:subtitle>
        </.header>
      </div>

      <.form
        for={@form}
        id="form"
        phx-submit="update_setting"
        phx-change="validate_setting"
      >
        <.input
          field={@form[:title]}
          type="text"
          label={gettext("Title")}
          required
        />
        <.button variant="primary" phx-disable-with={gettext("Changing...")}>
          {gettext("Save Settings")}
        </.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    setting = Settings.get_setting!(socket.assigns.current_scope)
    setting_changeset = Settings.change_setting(socket.assigns.current_scope, setting)

    socket =
      socket
      |> assign(:setting, setting)
      |> assign(:form, to_form(setting_changeset))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_setting", %{"setting" => setting_params}, socket) do
    form =
      socket.assigns.current_scope
      |> Settings.change_setting(socket.assigns.setting, setting_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("update_setting", %{"setting" => setting_params}, socket) do
    case Settings.save_setting(
           socket.assigns.current_scope,
           socket.assigns.setting,
           setting_params
         ) do
      {:ok, _setting} ->
        info = gettext("Settings saved")
        {:noreply, socket |> put_flash(:info, info)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, action: :insert))}
    end
  end
end
