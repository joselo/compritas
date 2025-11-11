defmodule Billing.ProductsTest do
  use Billing.DataCase

  alias Billing.Products

  describe "products" do
    alias Billing.Products.Product

    import Billing.AccountsFixtures, only: [user_scope_fixture: 0]
    import Billing.ProductsFixtures

    @invalid_attrs %{name: nil, price: nil}

    test "list_products/0 returns all products" do
      scope = user_scope_fixture()
      product = product_fixture(scope)

      assert Products.list_products(scope) == [product]
    end

    test "get_product!/1 returns the product with given id" do
      scope = user_scope_fixture()
      product = product_fixture(scope)

      assert Products.get_product!(scope, product.id) == product
    end

    test "create_product/1 with valid data creates a product" do
      scope = user_scope_fixture()
      valid_attrs = %{name: "some name", price: "120.5"}

      assert {:ok, %Product{} = product} = Products.create_product(scope, valid_attrs)
      assert product.name == "some name"
      assert product.price == Decimal.new("120.5")
    end

    test "create_product/1 with invalid data returns error changeset" do
      scope = user_scope_fixture()

      assert {:error, %Ecto.Changeset{}} = Products.create_product(scope, @invalid_attrs)
    end

    test "update_product/2 with valid data updates the product" do
      scope = user_scope_fixture()
      product = product_fixture(scope)

      update_attrs = %{name: "some updated name", price: "456.7"}

      assert {:ok, %Product{} = product} = Products.update_product(scope, product, update_attrs)
      assert product.name == "some updated name"
      assert product.price == Decimal.new("456.7")
    end

    test "update_product/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      product = product_fixture(scope)

      assert {:error, %Ecto.Changeset{}} = Products.update_product(scope, product, @invalid_attrs)
      assert product == Products.get_product!(scope, product.id)
    end

    test "delete_product/1 deletes the product" do
      scope = user_scope_fixture()
      product = product_fixture(scope)

      assert {:ok, %Product{}} = Products.delete_product(scope, product)
      assert_raise Ecto.NoResultsError, fn -> Products.get_product!(scope, product.id) end
    end

    test "change_product/1 returns a product changeset" do
      scope = user_scope_fixture()
      product = product_fixture(scope)

      assert %Ecto.Changeset{} = Products.change_product(scope, product)
    end
  end
end
