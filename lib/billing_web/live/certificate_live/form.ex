defmodule BillingWeb.CertificateLive.Form do
  use BillingWeb, :live_view

  alias Billing.Certificates
  alias Billing.Certificates.Certificate

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage certificate records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="certificate-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} label="Name" />
        <.live_file_input upload={@uploads.certificate_file} />

        <section phx-drop-target={@uploads.certificate_file.ref}>
          <article :for={entry <- @uploads.certificate_file.entries} class="upload-entry">
            <progress value={entry.progress} max="100">{entry.progress}% </progress>
            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              aria-label="cancel"
            >
              &times;
            </button>
            <p
              :for={err <- upload_errors(@uploads.certificate_file, entry)}
              class="alert alert-danger"
            >
              {error_to_string(err)}
            </p>
          </article>

          <p :for={err <- upload_errors(@uploads.certificate_file)} class="alert alert-danger">
            {error_to_string(err)}
          </p>
        </section>

        <.input field={@form[:password]} type="password" label="Password" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Certificate</.button>
          <.button navigate={return_path(@return_to, @certificate)}>Cancel</.button>
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
     |> assign(:uploaded_files, [])
     |> allow_upload(:certificate_file, accept: ~w(.p12), max_entries: 1)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    certificate = Certificates.get_certificate!(id)

    socket
    |> assign(:page_title, "Edit Certificate")
    |> assign(:certificate, certificate)
    |> assign(:form, to_form(Certificates.change_certificate(certificate)))
  end

  defp apply_action(socket, :new, _params) do
    certificate = %Certificate{}

    socket
    |> assign(:page_title, "New Certificate")
    |> assign(:certificate, certificate)
    |> assign(:form, to_form(Certificates.change_certificate(certificate)))
  end

  @impl true
  def handle_event("validate", %{"certificate" => certificate_params}, socket) do
    changeset = Certificates.change_certificate(socket.assigns.certificate, certificate_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"certificate" => certificate_params}, socket) do
    save_certificate(socket, socket.assigns.live_action, certificate_params)
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :certificate_file, ref)}
  end

  defp save_certificate(socket, :edit, certificate_params) do
    certificate_params = set_uploads_to_params(socket, certificate_params)
    password = certificate_params["password"]

    with {:ok, certificate} <-
           Certificates.update_certificate(socket.assigns.certificate, certificate_params),
         {:ok, certificate} <- Certificates.update_certificate_password(certificate, password) do
      {:noreply,
       socket
       |> put_flash(:info, "Certificate updated successfully")
       |> push_navigate(to: return_path(socket.assigns.return_to, certificate))}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      _error ->
        {:noreply, put_flash(socket, :error, "Error saving certificate")}
    end
  end

  defp save_certificate(socket, :new, certificate_params) do
    certificate_params = set_uploads_to_params(socket, certificate_params)
    password = certificate_params["password"]

    with {:ok, certificate} <- Certificates.create_certificate(certificate_params),
         {:ok, certificate} <- Certificates.update_certificate_password(certificate, password) do
      {:noreply,
       socket
       |> put_flash(:info, "Certificate created successfully")
       |> push_navigate(to: return_path(socket.assigns.return_to, certificate))}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      _error ->
        {:noreply, put_flash(socket, :error, "Error saving certificate")}
    end
  end

  defp return_path("index", _certificate), do: ~p"/certificates"
  defp return_path("show", certificate), do: ~p"/certificates/#{certificate}"

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp set_uploads_to_params(socket, params) do
    uploaded_files =
      consume_uploaded_entries(socket, :certificate_file, fn %{path: path}, entry ->
        file_name = entry.uuid

        dest =
          Path.join(Billing.get_storage_path(), file_name)

        File.cp!(path, dest)
        {:ok, Path.basename(dest)}
      end)

    case uploaded_files do
      [file_name | _tail] ->
        Map.put(params, "file", file_name)

      _ ->
        params
    end
  end
end
