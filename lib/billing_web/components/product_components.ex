defmodule BillingWeb.ProductComponents do
  use Phoenix.Component
  use Gettext, backend: BillingWeb.Gettext

  attr :images, :list, required: true
  attr :title, :string, required: true

  def gallery(assigns) do
    assigns = assign_new(assigns, :images_with_index, fn -> Enum.with_index(assigns.images) end)

    ~H"""
    <div>
      <ul class="space-y-4">
        <li :for={{image, _index} <- @images_with_index} class="">
          <img src={image} alt={@title} loading="lazy" class="rounded" />
        </li>
      </ul>
    </div>
    """
  end

  attr :files, :list, required: true

  def files(assigns) do
    assigns =
      assign_new(assigns, :image, fn ->
        Enum.at(assigns.files, 0)
      end)

    ~H"""
    <img
      :if={@image}
      class="w-32 h-32 flex items-center justify-center bg-base-200 text-base-content rounded"
      src={@image}
    />

    <div
      :if={!@image}
      class="w-32 h-32 flex items-center justify-center bg-base-200 text-base-content border border-dashed border-neutral rounded"
    >
      <span class="text-sm">Sin imagen</span>
    </div>
    """
  end
end
