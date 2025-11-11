defmodule Billing.EmissionProfilesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Billing.EmissionProfiles` context.
  """

  import Billing.CertificatesFixtures
  import Billing.CompaniesFixtures

  @doc """
  Generate a emission_profile.
  """
  def emission_profile_fixture(scope, attrs \\ %{}) do
    certificate = certificate_fixture(scope)
    company = company_fixture(scope)

    attrs =
      attrs
      |> Enum.into(%{
        name: "Matrix",
        certificate_id: certificate.id,
        company_id: company.id,
        sequence: 1
      })

    {:ok, emission_profile} = Billing.EmissionProfiles.create_emission_profile(scope, attrs)

    emission_profile
  end
end
