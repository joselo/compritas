defmodule Billing.CartsTest do
  use Billing.DataCase

  alias Billing.Carts
  alias Billing.Cart
  alias Repo

  describe "carts" do
    alias Billing.Carts.Cart

    import Billing.CartsFixtures

    @invalid_attrs %{cart_uuid: nil, product_name: nil, product_price: nil}

    test "list_carts/1 returns all carts" do
      cart = cart_fixture()

      assert Carts.list_carts(cart.cart_uuid) == [cart]
    end

    test "get_cart!/1 returns the cart with given id" do
      cart = cart_fixture()
      assert Carts.get_cart!(cart.id) == cart
    end

    test "create_cart/1 with valid data creates a cart" do
      valid_attrs = %{
        cart_uuid: "7488a646-e31f-11e4-aace-600308960662",
        product_name: "Product",
        product_price: "5.0"
      }

      assert {:ok, %Cart{} = cart} = Carts.create_cart(valid_attrs)
      assert cart.cart_uuid == "7488a646-e31f-11e4-aace-600308960662"
      assert cart.product_name == "Product"
      assert cart.product_price == Decimal.new("5.0")
    end

    test "create_cart/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Carts.create_cart(@invalid_attrs)
    end

    test "update_cart/2 with valid data updates the cart" do
      cart = cart_fixture()

      update_attrs = %{
        cart_uuid: "7488a646-e31f-11e4-aace-600308960668",
        product_name: "Product Updated",
        product_price: Decimal.new("10.0")
      }

      assert {:ok, %Cart{} = cart} = Carts.update_cart(cart, update_attrs)
      assert cart.cart_uuid == "7488a646-e31f-11e4-aace-600308960668"
      assert cart.product_name == "Product Updated"
      assert cart.product_price == Decimal.new("10.0")
    end

    test "update_cart/2 with invalid data returns error changeset" do
      cart = cart_fixture()
      assert {:error, %Ecto.Changeset{}} = Carts.update_cart(cart, @invalid_attrs)
      assert cart == Carts.get_cart!(cart.id)
    end

    test "delete_cart/1 deletes the cart" do
      cart = cart_fixture()
      assert {:ok, %Cart{}} = Carts.delete_cart(cart)
      assert_raise Ecto.NoResultsError, fn -> Carts.get_cart!(cart.id) end
    end

    test "change_cart/1 returns a cart changeset" do
      cart = cart_fixture()
      assert %Ecto.Changeset{} = Carts.change_cart(cart)
    end
  end
end
