defmodule BillingWeb.EmissionProfileLive.Show do
  use BillingWeb, :live_view

  alias Billing.EmissionProfiles

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Emission profile {@emission_profile.id}
        <:subtitle>This is a emission_profile record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/emission_profiles"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button
            variant="primary"
            navigate={~p"/emission_profiles/#{@emission_profile}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Edit emission_profile
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@emission_profile.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Emission profile")
     |> assign(:emission_profile, EmissionProfiles.get_emission_profile!(id))}
  end
end
