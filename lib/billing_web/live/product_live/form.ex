defmodule BillingWeb.ProductLive.Form do
  use BillingWeb, :live_view

  alias Billing.Products
  alias Billing.Products.Product
  alias Billing.Storage

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} settings={@settings}>
      <.header>
        {@page_title}
      </.header>

      <.form for={@form} id="product-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label={gettext("Name")} />
        <.input field={@form[:price]} type="number" label={gettext("Price")} step="any" />
        <.input field={@form[:content]} type="textarea" label={gettext("Description")} />

        <div class="fieldset mb-2">
          <label>
            <span class="label mb-1">{gettext("Pictures")}</span>

            <div>
              <.live_file_input upload={@uploads.files} class="file-input" />
            </div>
          </label>
        </div>

        <.uploads_section uploads={@uploads} />

        <footer>
          <.button phx-disable-with="Saving..." variant="primary">{gettext("Save Product")}</.button>
          <.button navigate={return_path(@return_to, @product)}>{gettext("Cancel")}</.button>
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
     |> apply_action(socket.assigns.live_action, params)
     |> allow_upload(:files, accept: ~w(.jpg .jpeg .png), max_entries: 5)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    product = Products.get_product!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, gettext("Edit Product"))
    |> assign(:product, product)
    |> assign(:form, to_form(Products.change_product(socket.assigns.current_scope, product)))
  end

  defp apply_action(socket, :new, _params) do
    product = %Product{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, gettext("New Product"))
    |> assign(:product, product)
    |> assign(:form, to_form(Products.change_product(socket.assigns.current_scope, product)))
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      Products.change_product(
        socket.assigns.current_scope,
        socket.assigns.product,
        product_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.live_action, product_params)
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  defp save_product(socket, :edit, product_params) do
    params = consume_files(socket, product_params)

    case Products.update_product(socket.assigns.current_scope, socket.assigns.product, params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Product updated successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, product))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_product(socket, :new, product_params) do
    params = consume_files(socket, product_params)

    case Products.create_product(socket.assigns.current_scope, params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Product created successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, product))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _product), do: ~p"/products"
  defp return_path("show", product), do: ~p"/products/#{product}"

  attr :uploads, :any, required: true

  defp uploads_section(assigns) do
    ~H"""
    <section phx-drop-target={@uploads.files.ref}>
      <%!-- render each files entry --%>
      <article :for={entry <- @uploads.files.entries} class="upload-entry">
        <figure>
          <.live_img_preview entry={entry} />
          <figcaption>{entry.client_name}</figcaption>
        </figure>

        <%!-- entry.progress will update automatically for in-flight entries --%>
        <progress value={entry.progress} max="100">{entry.progress}% </progress>

        <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
        <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} aria-label="cancel">
          &times;
        </button>

        <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
        <.error :for={err <- upload_errors(@uploads.files, entry)}>
          {error_to_string(err)}
        </.error>
      </article>

      <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
      <.error :for={err <- upload_errors(@uploads.files)} class="alert alert-error">
        {error_to_string(err)}
      </.error>
    </section>
    """
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"

  defp consume_files(socket, params) do
    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
        extname = Path.extname(entry.client_name)
        file_name = entry.uuid <> extname
        user_id = socket.assigns.current_scope.user.uuid
        dest = Storage.upload_path(socket.assigns.current_scope, file_name)

        Storage.copy_file!(path, dest)

        {:ok, ~p"/uploads/#{user_id}/#{Path.basename(dest)}"}
      end)

    files = socket.assigns.product.files ++ uploaded_files
    Map.put(params, "files", files)
  end
end
