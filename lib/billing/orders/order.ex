defmodule Billing.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias Billing.Orders.OrderItem

  schema "orders" do
    field :full_name, :string
    field :email, :string
    field :identification_number, :string
    field :identification_type, Ecto.Enum, values: [:cedula, :ruc]
    field :address, :string
    field :phone_number, :string
    field :amount, :decimal
    field :user_id, :id

    timestamps(type: :utc_datetime)

    has_many :items, OrderItem, foreign_key: :order_id
  end

  @doc false
  def changeset(order, attrs, user_scope) do
    order
    |> cast(attrs, [
      :full_name,
      :email,
      :identification_number,
      :identification_type,
      :address,
      :phone_number
    ])
    |> validate_required([
      :full_name,
      :email,
      :identification_number,
      :identification_type,
      :address,
      :phone_number
    ])
    |> cast_assoc(:items, with: &OrderItem.changeset(&1, &2, user_scope))
    |> put_change(:user_id, user_scope.user.id)
  end
end
