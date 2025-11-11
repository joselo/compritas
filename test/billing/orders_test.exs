defmodule Billing.OrdersTest do
  use Billing.DataCase

  alias Billing.Orders

  describe "orders" do
    alias Billing.Orders.Order

    import Billing.AccountsFixtures, only: [user_scope_fixture: 0]
    import Billing.OrdersFixtures

    @invalid_attrs %{full_name: nil, phone_number: nil}

    test "list_orders/0 returns all orders" do
      scope = user_scope_fixture()
      order = order_fixture(scope)

      [result | tail] = Orders.list_orders(scope)

      assert result.id == order.id
      assert tail == []
    end

    test "get_order!/1 returns the order with given id" do
      scope = user_scope_fixture()
      order = order_fixture(scope)

      assert Orders.get_order!(scope, order.id) == order
    end

    test "create_order/1 with valid data creates a order" do
      scope = user_scope_fixture()

      valid_attrs = %{
        full_name: "Raiden",
        email: "raiden@example.com",
        identification_number: "1234567890",
        identification_type: "cedula",
        address: "Address",
        phone_number: "123456789",
        items: [
          %{
            name: "Product",
            price: "5.0"
          }
        ]
      }

      assert {:ok, %Order{} = order} = Orders.create_order(scope, valid_attrs)
      assert order.full_name == "Raiden"
      assert order.phone_number == "123456789"

      [item | tail] = order.items

      assert item.name == "Product"
      assert item.price == Decimal.new("5.0")
      assert tail == []
    end

    test "create_order/1 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Orders.create_order(scope, @invalid_attrs)
    end

    test "update_order/2 with valid data updates the order" do
      scope = user_scope_fixture()
      order = order_fixture(scope)

      update_attrs = %{
        full_name: "some updated full_name",
        phone_number: "some updated phone_number"
      }

      assert {:ok, %Order{} = order} = Orders.update_order(scope, order, update_attrs)
      assert order.full_name == "some updated full_name"
      assert order.phone_number == "some updated phone_number"
    end

    test "update_order/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      order = order_fixture(scope)

      assert {:error, %Ecto.Changeset{}} = Orders.update_order(scope, order, @invalid_attrs)
      assert order == Orders.get_order!(scope, order.id)
    end

    test "delete_order/1 deletes the order" do
      scope = user_scope_fixture()
      order = order_fixture(scope)

      assert {:ok, %Order{}} = Orders.delete_order(scope, order)
      assert_raise Ecto.NoResultsError, fn -> Orders.get_order!(scope, order.id) end
    end

    test "change_order/1 returns a order changeset" do
      scope = user_scope_fixture()
      order = order_fixture(scope)

      assert %Ecto.Changeset{} = Orders.change_order(scope, order)
    end
  end
end
