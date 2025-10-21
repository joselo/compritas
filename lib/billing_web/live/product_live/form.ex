defmodule BillingWeb.ProductLive.Form do
  use BillingWeb, :live_view

  alias Billing.Products
  alias Billing.Products.Product

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage product records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="product-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:price]} type="number" label="Price" step="any" />
        <.live_file_input upload={@uploads.files} />
        <.uploads_section uploads={@uploads} />

        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Product</.button>
          <.button navigate={return_path(@return_to, @product)}>Cancel</.button>
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
    product = Products.get_product!(id)

    socket
    |> assign(:page_title, "Edit Product")
    |> assign(:product, product)
    |> assign(:form, to_form(Products.change_product(product)))
  end

  defp apply_action(socket, :new, _params) do
    product = %Product{}

    socket
    |> assign(:page_title, "New Product")
    |> assign(:product, product)
    |> assign(:form, to_form(Products.change_product(product)))
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset = Products.change_product(socket.assigns.product, product_params)
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

    case Products.update_product(socket.assigns.product, params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, product))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_product(socket, :new, product_params) do
    params = consume_files(socket, product_params)

    case Products.create_product(params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product created successfully")
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
        <p :for={err <- upload_errors(@uploads.files, entry)} class="alert alert-danger">
          {error_to_string(err)}
        </p>
      </article>

      <%!-- Phoenix.Component.upload_errors/1 returns a list of error atoms --%>
      <p :for={err <- upload_errors(@uploads.files)} class="alert alert-danger">
        {error_to_string(err)}
      </p>
    </section>
    """
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"

  defp consume_files(socket, params) do
    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: path}, _entry ->
        dest =
          Path.join(Application.app_dir(:billing, "priv/static/uploads"), Path.basename(path))

        # You will need to create `priv/static/uploads` for `File.cp!/2` to work.
        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    files = socket.assigns.product.files ++ uploaded_files
    Map.put(params, "files", files)
  end
end
