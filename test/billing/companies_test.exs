defmodule Billing.CompaniesTest do
  use Billing.DataCase

  alias Billing.Companies

  describe "companies" do
    alias Billing.Companies.Company

    import Billing.AccountsFixtures, only: [user_scope_fixture: 0]
    import Billing.CompaniesFixtures

    @invalid_attrs %{name: nil, address: nil, identification_number: nil}

    test "list_companies/0 returns all companies" do
      scope = user_scope_fixture()
      company = company_fixture(scope)

      assert Companies.list_companies(scope) == [company]
    end

    test "get_company!/1 returns the company with given id" do
      scope = user_scope_fixture()
      company = company_fixture(scope)

      assert Companies.get_company!(scope, company.id) == company
    end

    test "create_company/1 with valid data creates a company" do
      scope = user_scope_fixture()

      valid_attrs = %{
        name: "some name",
        address: "some address",
        identification_number: "some identification_number"
      }

      assert {:ok, %Company{} = company} = Companies.create_company(scope, valid_attrs)
      assert company.name == "some name"
      assert company.address == "some address"
      assert company.identification_number == "some identification_number"
    end

    test "create_company/1 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Companies.create_company(scope, @invalid_attrs)
    end

    test "update_company/2 with valid data updates the company" do
      scope = user_scope_fixture()
      company = company_fixture(scope)

      update_attrs = %{
        name: "some updated name",
        address: "some updated address",
        identification_number: "some updated identification_number"
      }

      assert {:ok, %Company{} = company} = Companies.update_company(scope, company, update_attrs)
      assert company.name == "some updated name"
      assert company.address == "some updated address"
      assert company.identification_number == "some updated identification_number"
    end

    test "update_company/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      company = company_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Companies.update_company(scope, company, @invalid_attrs)

      assert company == Companies.get_company!(scope, company.id)
    end

    test "delete_company/1 deletes the company" do
      scope = user_scope_fixture()
      company = company_fixture(scope)

      assert {:ok, %Company{}} = Companies.delete_company(scope, company)
      assert_raise Ecto.NoResultsError, fn -> Companies.get_company!(scope, company.id) end
    end

    test "change_company/1 returns a company changeset" do
      scope = user_scope_fixture()
      company = company_fixture(scope)

      assert %Ecto.Changeset{} = Companies.change_company(scope, company)
    end
  end
end
