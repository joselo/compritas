defmodule Billing.Customers.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields [
    :full_name,
    :email,
    :identification_number,
    :identification_type,
    :address,
    :phone_number
  ]

  schema "customers" do
    field :full_name, :string
    field :email, :string
    field :identification_number, :string
    field :identification_type, Ecto.Enum, values: [:cedula, :ruc]
    field :address, :string
    field :phone_number, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(customer, attrs, user_scope) do
    customer
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> put_change(:user_id, user_scope.user.id)
  end

  def list_required_fields do
    @required_fields
  end
end
