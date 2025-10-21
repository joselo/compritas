defmodule BillingWeb.CompanyLive.Form do
  use BillingWeb, :live_view

  alias Billing.Companies
  alias Billing.Companies.Company

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage company records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="company-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:identification_number]} type="text" label="Identification number" />
        <.input field={@form[:address]} type="text" label="Address" />
        <.input field={@form[:name]} type="text" label="Name" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Company</.button>
          <.button navigate={return_path(@return_to, @company)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    company = Companies.get_company!(id)

    socket
    |> assign(:page_title, "Edit Company")
    |> assign(:company, company)
    |> assign(:form, to_form(Companies.change_company(company)))
  end

  defp apply_action(socket, :new, _params) do
    company = %Company{}

    socket
    |> assign(:page_title, "New Company")
    |> assign(:company, company)
    |> assign(:form, to_form(Companies.change_company(company)))
  end

  @impl true
  def handle_event("validate", %{"company" => company_params}, socket) do
    changeset = Companies.change_company(socket.assigns.company, company_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"company" => company_params}, socket) do
    save_company(socket, socket.assigns.live_action, company_params)
  end

  defp save_company(socket, :edit, company_params) do
    case Companies.update_company(socket.assigns.company, company_params) do
      {:ok, company} ->
        {:noreply,
         socket
         |> put_flash(:info, "Company updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, company))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_company(socket, :new, company_params) do
    case Companies.create_company(company_params) do
      {:ok, company} ->
        {:noreply,
         socket
         |> put_flash(:info, "Company created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, company))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _company), do: ~p"/companies"
  defp return_path("show", company), do: ~p"/companies/#{company}"
end
