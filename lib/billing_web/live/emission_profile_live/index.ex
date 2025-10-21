defmodule BillingWeb.EmissionProfileLive.Index do
  use BillingWeb, :live_view

  alias Billing.EmissionProfiles

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Emission profiles
        <:actions>
          <.button variant="primary" navigate={~p"/emission_profiles/new"}>
            <.icon name="hero-plus" /> New Emission profile
          </.button>
        </:actions>
      </.header>

      <.table
        id="emission_profiles"
        rows={@streams.emission_profiles}
        row_click={
          fn {_id, emission_profile} -> JS.navigate(~p"/emission_profiles/#{emission_profile}") end
        }
      >
        <:col :let={{_id, emission_profile}} label="Name">{emission_profile.name}</:col>
        <:action :let={{_id, emission_profile}}>
          <div class="sr-only">
            <.link navigate={~p"/emission_profiles/#{emission_profile}"}>Show</.link>
          </div>
          <.link navigate={~p"/emission_profiles/#{emission_profile}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, emission_profile}}>
          <.link
            phx-click={JS.push("delete", value: %{id: emission_profile.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Emission profiles")
     |> stream(:emission_profiles, EmissionProfiles.list_emission_profiles())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    emission_profile = EmissionProfiles.get_emission_profile!(id)
    {:ok, _} = EmissionProfiles.delete_emission_profile(emission_profile)

    {:noreply, stream_delete(socket, :emission_profiles, emission_profile)}
  end
end
