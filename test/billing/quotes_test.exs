defmodule Billing.QuotesTest do
  use Billing.DataCase

  import Billing.AccountsFixtures, only: [user_scope_fixture: 0]
  import Billing.CustomersFixtures
  import Billing.EmissionProfilesFixtures

  alias Billing.Quotes
  alias Billing.Repo
  alias Billing.Quotes.Quote
  alias Billing.Quotes.QuoteItem

  setup do
    scope = user_scope_fixture()
    customer = customer_fixture(scope)
    emission_profile = emission_profile_fixture(scope)

    {:ok, customer: customer, emission_profile: emission_profile}
  end

  describe "quotes" do
    alias Billing.Quotes.Quote

    import Billing.QuotesFixtures

    @invalid_attrs %{issued_at: nil}

    test "list_quotes/0 returns all quotes" do
      scope = user_scope_fixture()
      quote = quote_fixture(scope)

      quote =
        Quote
        |> Repo.get!(quote.id)
        |> Repo.preload([:customer])

      assert Quotes.list_quotes(scope) == [quote]
    end

    test "get_quote!/1 returns the quote with given id" do
      scope = user_scope_fixture()
      quote = quote_fixture(scope)

      quote =
        Quote
        |> Repo.get!(quote.id)
        |> Repo.preload([:customer])

      result = Quotes.get_quote!(scope, quote.id)

      [item | tail] = result.items

      assert %QuoteItem{} = item
      assert tail == []
    end

    test "create_quote/1 with valid data creates a quote", %{
      customer: customer,
      emission_profile: emission_profile
    } do
      scope = user_scope_fixture()

      valid_attrs = %{
        customer_id: customer.id,
        emission_profile_id: emission_profile.id,
        issued_at: ~D[2025-08-28],
        description: "Quote Test",
        due_date: ~D[2025-08-28],
        amount: Decimal.new("10.0"),
        tax_rate: Decimal.new("15.0"),
        payment_method: :cash,
        items: [
          %{
            description: "Invoice Test",
            price: Decimal.new("10.0"),
            amount: Decimal.new("10.0"),
            tax_rate: Decimal.new("15.0")
          }
        ]
      }

      assert {:ok, %Quote{} = quote} = Quotes.create_quote(scope, valid_attrs)
      assert quote.issued_at == ~D[2025-08-28]
    end

    test "create_quote/1 with invalid data returns error changeset" do
      scope = user_scope_fixture()

      assert {:error, %Ecto.Changeset{}} = Quotes.create_quote(scope, @invalid_attrs)
    end

    test "update_quote/2 with valid data updates the quote" do
      scope = user_scope_fixture()
      quote = quote_fixture(scope)
      update_attrs = %{issued_at: ~D[2025-08-29]}

      assert {:ok, %Quote{} = quote} = Quotes.update_quote(scope, quote, update_attrs)
      assert quote.issued_at == ~D[2025-08-29]
    end

    test "update_quote/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      quote = quote_fixture(scope)

      quote =
        Quote
        |> Repo.get!(quote.id)
        |> Repo.preload([:customer, :items])

      assert {:error, %Ecto.Changeset{}} = Quotes.update_quote(scope, quote, @invalid_attrs)

      result = Quotes.get_quote!(scope, quote.id)
      assert result.id == quote.id

      [item | tail] = result.items

      assert %QuoteItem{} = item
      assert tail == []
    end

    test "delete_quote/1 deletes the quote" do
      scope = user_scope_fixture()
      quote = quote_fixture(scope)

      assert {:ok, %Quote{}} = Quotes.delete_quote(scope, quote)
      assert_raise Ecto.NoResultsError, fn -> Quotes.get_quote!(scope, quote.id) end
    end

    test "change_quote/1 returns a quote changeset" do
      scope = user_scope_fixture()
      quote = quote_fixture(scope)

      assert %Ecto.Changeset{} = Quotes.change_quote(scope, quote)
    end
  end
end
