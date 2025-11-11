defmodule Billing.CustomersTest do
  use Billing.DataCase

  alias Billing.Customers

  describe "customers" do
    alias Billing.Customers.Customer

    import Billing.AccountsFixtures, only: [user_scope_fixture: 0]
    import Billing.CustomersFixtures

    @invalid_attrs %{full_name: nil, email: nil}

    test "list_customers/0 returns all customers" do
      scope = user_scope_fixture()
      customer = customer_fixture(scope)

      assert Customers.list_customers(scope) == [customer]
    end

    test "get_customer!/1 returns the customer with given id" do
      scope = user_scope_fixture()
      customer = customer_fixture(scope)

      assert Customers.get_customer!(scope, customer.id) == customer
    end

    test "create_customer/1 with valid data creates a customer" do
      scope = user_scope_fixture()

      valid_attrs = %{
        full_name: "Raiden",
        email: "raiden@example.com",
        identification_number: "1234567890",
        identification_type: "cedula",
        address: "Address",
        phone_number: "123456789"
      }

      assert {:ok, %Customer{} = customer} = Customers.create_customer(scope, valid_attrs)
      assert customer.full_name == "Raiden"
      assert customer.email == "raiden@example.com"
    end

    test "create_customer/1 with invalid data returns error changeset" do
      scope = user_scope_fixture()

      assert {:error, %Ecto.Changeset{}} = Customers.create_customer(scope, @invalid_attrs)
    end

    test "update_customer/2 with valid data updates the customer" do
      scope = user_scope_fixture()
      customer = customer_fixture(scope)

      update_attrs = %{full_name: "some updated full_name", email: "some updated email"}

      assert {:ok, %Customer{} = customer} =
               Customers.update_customer(scope, customer, update_attrs)

      assert customer.full_name == "some updated full_name"
      assert customer.email == "some updated email"
    end

    test "update_customer/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      customer = customer_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Customers.update_customer(scope, customer, @invalid_attrs)

      assert customer == Customers.get_customer!(scope, customer.id)
    end

    test "delete_customer/1 deletes the customer" do
      scope = user_scope_fixture()
      customer = customer_fixture(scope)

      assert {:ok, %Customer{}} = Customers.delete_customer(scope, customer)
      assert_raise Ecto.NoResultsError, fn -> Customers.get_customer!(scope, customer.id) end
    end

    test "change_customer/1 returns a customer changeset" do
      scope = user_scope_fixture()
      customer = customer_fixture(scope)

      assert %Ecto.Changeset{} = Customers.change_customer(scope, customer)
    end
  end
end
