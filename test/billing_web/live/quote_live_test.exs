defmodule BillingWeb.QuoteLiveTest do
  use BillingWeb.ConnCase

  import Phoenix.LiveViewTest
  import Billing.QuotesFixtures
  import Billing.CustomersFixtures
  import Billing.EmissionProfilesFixtures
  import Billing.AccountsFixtures

  @create_attrs %{
    issued_at: ~D[2025-08-28],
    description: "Invoice Test",
    due_date: ~D[2025-08-28],
    amount: Decimal.new("10.0"),
    tax_rate: Decimal.new("15.0"),
    payment_method: :cash
  }

  @update_attrs %{issued_at: "2025-08-29"}
  @invalid_attrs %{issued_at: nil}
  defp create_invoice(_) do
    quote = quote_fixture()

    %{quote: quote}
  end

  setup %{conn: conn} do
    customer = customer_fixture()
    emission_profile = emission_profile_fixture()
    user = user_fixture()

    %{conn: log_in_user(conn, user), customer: customer, emission_profile: emission_profile}
  end

  describe "Index" do
    setup [:create_invoice]

    test "lists all quotes", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/quotes")

      assert html =~ "Listado de Facturas"
    end

    test "saves new quote", %{
      conn: conn,
      customer: customer,
      emission_profile: emission_profile
    } do
      {:ok, index_live, _html} = live(conn, ~p"/quotes")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Invoice")
               |> render_click()
               |> follow_redirect(conn, ~p"/quotes/new")

      assert render(form_live) =~ "New Invoice"

      assert form_live
             |> form("#quote-form", quote: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      attrs =
        @create_attrs
        |> Map.put(:customer_id, customer.id)
        |> Map.put(:emission_profile_id, emission_profile.id)

      assert {:ok, index_live, _html} =
               form_live
               |> form("#quote-form", quote: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/quotes")

      html = render(index_live)
      assert html =~ "Invoice created successfully"
    end

    test "updates quote in listing", %{conn: conn, quote: quote} do
      {:ok, index_live, _html} = live(conn, ~p"/quotes")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#quotes-#{quote.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/quotes/#{quote}/edit")

      assert render(form_live) =~ "Edit Invoice"

      assert form_live
             |> form("#quote-form", quote: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#quote-form", quote: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/quotes")

      html = render(index_live)
      assert html =~ "Invoice updated successfully"
    end

    test "deletes quote in listing", %{conn: conn, quote: quote} do
      {:ok, index_live, _html} = live(conn, ~p"/quotes")

      assert index_live |> element("#quotes-#{quote.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#quotes-#{quote.id}")
    end
  end

  describe "Show" do
    setup [:create_invoice]

    test "displays quote", %{conn: conn, quote: quote} do
      {:ok, _show_live, html} = live(conn, ~p"/quotes/#{quote}")

      assert html =~ "Show Invoice"
    end

    test "updates quote and returns to show", %{conn: conn, quote: quote} do
      {:ok, show_live, _html} = live(conn, ~p"/quotes/#{quote}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/quotes/#{quote}/edit?return_to=show")

      assert render(form_live) =~ "Edit Invoice"

      assert form_live
             |> form("#quote-form", quote: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#quote-form", quote: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/quotes/#{quote}")

      html = render(show_live)
      assert html =~ "Invoice updated successfully"
    end
  end
end
