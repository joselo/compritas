defmodule Billing.EmissionProfilesTest do
  use Billing.DataCase

  import Billing.AccountsFixtures, only: [user_scope_fixture: 0]
  import Billing.CertificatesFixtures
  import Billing.CompaniesFixtures

  alias Billing.EmissionProfiles

  setup do
    scope = user_scope_fixture()
    certificate = certificate_fixture(scope)
    company = company_fixture(scope)

    {:ok, certificate: certificate, company: company}
  end

  describe "emission_profiles" do
    alias Billing.EmissionProfiles.EmissionProfile

    import Billing.EmissionProfilesFixtures

    @invalid_attrs %{name: nil}

    test "list_emission_profiles/0 returns all emission_profiles" do
      scope = user_scope_fixture()
      emission_profile = emission_profile_fixture(scope)

      assert EmissionProfiles.list_emission_profiles(scope) == [emission_profile]
    end

    test "get_emission_profile!/1 returns the emission_profile with given id" do
      scope = user_scope_fixture()
      emission_profile = emission_profile_fixture(scope)

      assert EmissionProfiles.get_emission_profile!(scope, emission_profile.id) ==
               emission_profile
    end

    test "create_emission_profile/1 with valid data creates a emission_profile", %{
      certificate: certificate,
      company: company
    } do
      scope = user_scope_fixture()

      valid_attrs = %{
        name: "some name",
        certificate_id: certificate.id,
        company_id: company.id,
        sequence: 1
      }

      assert {:ok, %EmissionProfile{} = emission_profile} =
               EmissionProfiles.create_emission_profile(scope, valid_attrs)

      assert emission_profile.name == "some name"
    end

    test "create_emission_profile/1 with invalid data returns error changeset" do
      scope = user_scope_fixture()

      assert {:error, %Ecto.Changeset{}} =
               EmissionProfiles.create_emission_profile(scope, @invalid_attrs)
    end

    test "update_emission_profile/2 with valid data updates the emission_profile" do
      scope = user_scope_fixture()
      emission_profile = emission_profile_fixture(scope)
      update_attrs = %{name: "some updated name"}

      assert {:ok, %EmissionProfile{} = emission_profile} =
               EmissionProfiles.update_emission_profile(scope, emission_profile, update_attrs)

      assert emission_profile.name == "some updated name"
    end

    test "update_emission_profile/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      emission_profile = emission_profile_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               EmissionProfiles.update_emission_profile(scope, emission_profile, @invalid_attrs)

      assert emission_profile ==
               EmissionProfiles.get_emission_profile!(scope, emission_profile.id)
    end

    test "delete_emission_profile/1 deletes the emission_profile" do
      scope = user_scope_fixture()
      emission_profile = emission_profile_fixture(scope)

      assert {:ok, %EmissionProfile{}} =
               EmissionProfiles.delete_emission_profile(scope, emission_profile)

      assert_raise Ecto.NoResultsError, fn ->
        EmissionProfiles.get_emission_profile!(scope, emission_profile.id)
      end
    end

    test "change_emission_profile/1 returns a emission_profile changeset" do
      scope = user_scope_fixture()
      emission_profile = emission_profile_fixture(scope)

      assert %Ecto.Changeset{} = EmissionProfiles.change_emission_profile(scope, emission_profile)
    end
  end
end
