defmodule BillingWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use BillingWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :return_to, :string, default: nil

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open">
      <input id="my-drawer-3" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content flex flex-col">
        <main class="px-4 py-4 sm:px-6 lg:px-8">
          <div class="mx-auto max-w-2xl space-y-4">
            <div class="flex items-center">
              <div class="flex-1">
                <label for="my-drawer-3" class="btn drawer-button lg:hidden">
                  <.icon name="hero-bars-3" />
                </label>

                <.button :if={@return_to} navigate={@return_to} class="btn">
                  <.icon name="hero-arrow-left" />
                </.button>
              </div>

              <div class="flex justify-end">
                <.theme_toggle />
              </div>
            </div>

            <div class="py-20">
              {render_slot(@inner_block)}
            </div>
          </div>
        </main>
      </div>
      <div class="drawer-side">
        <label for="my-drawer-3" aria-label="close sidebar" class="drawer-overlay"></label>
        <ul class="menu bg-base-200 min-h-full w-80 p-4">
          <li class="menu-title inline-block">
            <.link navigate={~p"/"}>
              <img src={~p"/images/logo.svg"} width="36" />
            </.link>
          </li>
          <li>
            <.link navigate={~p"/dashboard"}>
              <.icon name="hero-presentation-chart-bar" /> {gettext("Dashboard")}
            </.link>
          </li>
          <li>
            <.link navigate={~p"/agent_chat"}>
              <.icon name="hero-sparkles" /> {gettext("AI Chat")}
            </.link>
          </li>
          <li>
            <.link navigate={~p"/orders"}>
              <.icon name="hero-inbox" /> {gettext("Orders")}
            </.link>
          </li>
          <li>
            <.link navigate={~p"/quotes"}>
              <.icon name="hero-currency-dollar" /> {gettext("Quotes")}
            </.link>
          </li>
          <li>
            <.link navigate={~p"/electronic_invoices"}>
              <.icon name="hero-at-symbol" /> {gettext("E-Invoices")}
            </.link>
          </li>
          <li>
            <.link navigate={~p"/products"}>
              <.icon name="hero-tag" /> {gettext("Products")}
            </.link>
          </li>
          <li>
            <.link navigate={~p"/customers"}>
              <.icon name="hero-users" /> {gettext("Customers")}
            </.link>
          </li>
          <li>
            <.link navigate={~p"/certificates"}>
              <.icon name="hero-key" /> {gettext("Certificates")}
            </.link>
          </li>
          <li>
            <.link navigate={~p"/companies"}>
              <.icon name="hero-building-office" /> {gettext("Companies")}
            </.link>
          </li>
          <li>
            <.link navigate={~p"/emission_profiles"}>
              <.icon name="hero-finger-print" /> {gettext("Emission Profiles")}
            </.link>
          </li>
          <li>
            <.link navigate={~p"/settings"}>
              <.icon name="hero-adjustments-vertical" /> {gettext("Settings")}
            </.link>
          </li>
          <li>
            <.link navigate={~p"/users/settings"}>
              <.icon name="hero-user-circle" /> {gettext("Your Account")}
            </.link>
          </li>
          <li>
            <.link href={~p"/users/log-out"} method="delete">
              <.icon name="hero-arrow-left-start-on-rectangle" /> {gettext("Log out")}
            </.link>
          </li>
        </ul>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :return_to, :string, default: nil

  slot :inner_block, required: true

  def public(assigns) do
    ~H"""
    <header class="navbar mx-auto max-w-2xl">
      <div class="flex-1">
        <.link navigate={~p"/"} class="flex-1 flex w-fit items-center gap-2">
          <img src={~p"/images/logo.svg"} width="48" />
        </.link>
      </div>
      <div class="flex justify-end items-center space-x-2">
        <ul class="menu menu-horizontal">
          <%= if @current_scope do %>
            <li>
              <.link navigate={~p"/dashboard"} class="rounded-full">
                <.icon name="hero-inbox-arrow-down" /> {gettext("Manager")}
              </.link>
            </li>

            <li>
              <.link
                href={~p"/users/log-out"}
                method="delete"
                class="tooltip tooltip-bottom rounded-full"
                data-tip={gettext("Log out")}
              >
                <.icon name="hero-arrow-left-start-on-rectangle" />
              </.link>
            </li>
          <% else %>
            <li>
              <.link
                href={~p"/users/log-in"}
                class="tooltip tooltip-bottom rounded-full"
                data-tip={gettext("Log in")}
              >
                <.icon name="hero-power" />
              </.link>
            </li>
          <% end %>
        </ul>

        <div class="flex justify-end">
          <.theme_toggle />
        </div>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        <.button :if={@return_to} navigate={@return_to} class="btn">
          <.icon name="hero-arrow-left" />
        </.button>

        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
