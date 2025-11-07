defmodule BillingWeb.ProductComponents do
  use Phoenix.Component
  use Gettext, backend: BillingWeb.Gettext

  alias BillingWeb.CoreComponents

  attr :images, :list, required: true
  attr :title, :string, required: true

  def gallery(assigns) do
    assigns = assign_new(assigns, :images_with_index, fn -> Enum.with_index(assigns.images) end)

    ~H"""
    <div id="ProductGallery" phx-hook="Gallery">
      <ul class="space-y-4">
        <li :for={{image, _index} <- @images_with_index} class="">
          <img src={image} alt={@title} loading="lazy" class="rounded" />
        </li>
      </ul>
    </div>
    """
  end
end
