defmodule Billing.Certificates.Certificate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "certificates" do
    has_many :emission_profiles, Billing.EmissionProfiles.EmissionProfile

    field :name, :string
    field :file, :string
    field :password, :string, virtual: true
    field :encrypted_password, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(certificate, attrs, user_scope) do
    certificate
    |> cast(attrs, [:name, :file, :password])
    |> validate_required([:name, :file, :password])
    |> put_change(:user_id, user_scope.user.id)
  end
end
