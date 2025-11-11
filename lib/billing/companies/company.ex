defmodule Billing.Companies.Company do
  use Ecto.Schema
  import Ecto.Changeset

  schema "companies" do
    field :identification_number, :string
    field :address, :string
    field :name, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(company, attrs, user_scope) do
    company
    |> cast(attrs, [:identification_number, :address, :name])
    |> validate_required([:identification_number, :address, :name])
    |> put_change(:user_id, user_scope.user.id)
  end
end
