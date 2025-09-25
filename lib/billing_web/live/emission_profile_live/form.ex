defmodule BillingWeb.EmissionProfileLive.Form do
  use BillingWeb, :live_view

  alias Billing.EmissionProfiles
  alias Billing.EmissionProfiles.EmissionProfile

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage emission_profile records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="emission_profile-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:company_id]} type="select" label="Company" options={@companies} />
        <.input
          field={@form[:certificate_id]}
          type="select"
          label="Certificate"
          options={@certificates}
        />
        <.input field={@form[:sequence]} type="number" step="1" label="Sequence" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Emission profile</.button>
          <.button navigate={return_path(@return_to, @emission_profile)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    companies = Billing.Companies.list_companies() |> Enum.map(&{&1.name, &1.id})
    certificates = Billing.Certificates.list_certificates() |> Enum.map(&{&1.name, &1.id})

    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:companies, companies)
     |> assign(:certificates, certificates)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    emission_profile = EmissionProfiles.get_emission_profile!(id)

    socket
    |> assign(:page_title, "Edit Emission profile")
    |> assign(:emission_profile, emission_profile)
    |> assign(:form, to_form(EmissionProfiles.change_emission_profile(emission_profile)))
  end

  defp apply_action(socket, :new, _params) do
    emission_profile = %EmissionProfile{}

    socket
    |> assign(:page_title, "New Emission profile")
    |> assign(:emission_profile, emission_profile)
    |> assign(:form, to_form(EmissionProfiles.change_emission_profile(emission_profile)))
  end

  @impl true
  def handle_event("validate", %{"emission_profile" => emission_profile_params}, socket) do
    changeset =
      EmissionProfiles.change_emission_profile(
        socket.assigns.emission_profile,
        emission_profile_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"emission_profile" => emission_profile_params}, socket) do
    save_emission_profile(socket, socket.assigns.live_action, emission_profile_params)
  end

  defp save_emission_profile(socket, :edit, emission_profile_params) do
    case EmissionProfiles.update_emission_profile(
           socket.assigns.emission_profile,
           emission_profile_params
         ) do
      {:ok, emission_profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Emission profile updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, emission_profile))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_emission_profile(socket, :new, emission_profile_params) do
    case EmissionProfiles.create_emission_profile(emission_profile_params) do
      {:ok, emission_profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Emission profile created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, emission_profile))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _emission_profile), do: ~p"/emission_profiles"
  defp return_path("show", emission_profile), do: ~p"/emission_profiles/#{emission_profile}"
end
