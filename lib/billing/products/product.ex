defmodule Billing.Products.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :price, :decimal, default: 0.0
    field :files, {:array, :string}, default: []
    field :content, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs, user_scope) do
    product
    |> cast(attrs, [:name, :price, :files, :content])
    |> validate_required([:name, :price])
    |> put_change(:user_id, user_scope.user.id)
  end
end
