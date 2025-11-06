defmodule Billing.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :price, :decimal, default: 0.0
    field :files, {:array, :string}, default: []
    field :content, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :price, :files])
    |> validate_required([:name, :price])
  end
end
