defmodule Billing.OrdersTest do
  use Billing.DataCase

  alias Billing.Orders

  describe "orders" do
    alias Billing.Orders.Order

    import Billing.OrdersFixtures

    @invalid_attrs %{full_name: nil, phone_number: nil}

    test "list_orders/0 returns all orders" do
      order = order_fixture()
      assert Orders.list_orders() == [order]
    end

    test "get_order!/1 returns the order with given id" do
      order = order_fixture()
      assert Orders.get_order!(order.id) == order
    end

    test "create_order/1 with valid data creates a order" do
      valid_attrs = %{
        full_name: "some full_name",
        phone_number: "some phone_number",
        items: [
          %{
            name: "Product",
            price: "5.0"
          }
        ]
      }

      assert {:ok, %Order{} = order} = Orders.create_order(valid_attrs)
      assert order.full_name == "some full_name"
      assert order.phone_number == "some phone_number"

      [item | tail] = order.items

      assert item.name == "Product"
      assert item.price == Decimal.new("5.0")
      assert tail == []
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Orders.create_order(@invalid_attrs)
    end

    test "update_order/2 with valid data updates the order" do
      order = order_fixture()

      update_attrs = %{
        full_name: "some updated full_name",
        phone_number: "some updated phone_number"
      }

      assert {:ok, %Order{} = order} = Orders.update_order(order, update_attrs)
      assert order.full_name == "some updated full_name"
      assert order.phone_number == "some updated phone_number"
    end

    test "update_order/2 with invalid data returns error changeset" do
      order = order_fixture()
      assert {:error, %Ecto.Changeset{}} = Orders.update_order(order, @invalid_attrs)
      assert order == Orders.get_order!(order.id)
    end

    test "delete_order/1 deletes the order" do
      order = order_fixture()
      assert {:ok, %Order{}} = Orders.delete_order(order)
      assert_raise Ecto.NoResultsError, fn -> Orders.get_order!(order.id) end
    end

    test "change_order/1 returns a order changeset" do
      order = order_fixture()
      assert %Ecto.Changeset{} = Orders.change_order(order)
    end
  end
end
