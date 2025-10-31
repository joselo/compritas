defmodule Billing.EmissionProfiles.EmissionProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "emission_profiles" do
    belongs_to :certificate, Billing.Certificates.Certificate
    belongs_to :company, Billing.Companies.Company
    has_many :quotes, Billing.Quotes.Quote

    field :name, :string
    field :sequence, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(emission_profile, attrs) do
    emission_profile
    |> cast(attrs, [:name, :certificate_id, :company_id, :sequence])
    |> validate_required([:name, :certificate_id, :company_id, :sequence])
  end
end
