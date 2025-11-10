defmodule BillingWeb.EmissionProfileLive.Show do
  use BillingWeb, :live_view

  alias Billing.EmissionProfiles

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} return_to={~p"/emission_profiles"}>
      <.header>
        {gettext("Emission profile #%{emission_profile_id}",
          emission_profile_id: @emission_profile.id
        )}
        <:subtitle>{@emission_profile.inserted_at}</:subtitle>
        <:actions>
          <.button
            variant="primary"
            navigate={~p"/emission_profiles/#{@emission_profile}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> {gettext("Edit emission profile")}
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title={gettext("Name")}>{@emission_profile.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(
       :page_title,
       gettext("Emission profiles #%{emission_profile_id}", emission_profile_id: id)
     )
     |> assign(:emission_profile, EmissionProfiles.get_emission_profile!(id))}
  end
end
