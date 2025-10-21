defmodule BillingWeb.InvoiceLiveTest do
  use BillingWeb.ConnCase

  import Phoenix.LiveViewTest
  import Billing.InvoicesFixtures
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
    invoice = invoice_fixture()

    %{invoice: invoice}
  end

  setup %{conn: conn} do
    customer = customer_fixture()
    emission_profile = emission_profile_fixture()
    user = user_fixture()

    %{conn: log_in_user(conn, user), customer: customer, emission_profile: emission_profile}
  end

  describe "Index" do
    setup [:create_invoice]

    test "lists all invoices", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/invoices")

      assert html =~ "Listado de Facturas"
    end

    test "saves new invoice", %{
      conn: conn,
      customer: customer,
      emission_profile: emission_profile
    } do
      {:ok, index_live, _html} = live(conn, ~p"/invoices")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Invoice")
               |> render_click()
               |> follow_redirect(conn, ~p"/invoices/new")

      assert render(form_live) =~ "New Invoice"

      assert form_live
             |> form("#invoice-form", invoice: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      attrs =
        @create_attrs
        |> Map.put(:customer_id, customer.id)
        |> Map.put(:emission_profile_id, emission_profile.id)

      assert {:ok, index_live, _html} =
               form_live
               |> form("#invoice-form", invoice: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/invoices")

      html = render(index_live)
      assert html =~ "Invoice created successfully"
    end

    test "updates invoice in listing", %{conn: conn, invoice: invoice} do
      {:ok, index_live, _html} = live(conn, ~p"/invoices")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#invoices-#{invoice.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/invoices/#{invoice}/edit")

      assert render(form_live) =~ "Edit Invoice"

      assert form_live
             |> form("#invoice-form", invoice: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#invoice-form", invoice: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/invoices")

      html = render(index_live)
      assert html =~ "Invoice updated successfully"
    end

    test "deletes invoice in listing", %{conn: conn, invoice: invoice} do
      {:ok, index_live, _html} = live(conn, ~p"/invoices")

      assert index_live |> element("#invoices-#{invoice.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#invoices-#{invoice.id}")
    end
  end

  describe "Show" do
    setup [:create_invoice]

    test "displays invoice", %{conn: conn, invoice: invoice} do
      {:ok, _show_live, html} = live(conn, ~p"/invoices/#{invoice}")

      assert html =~ "Show Invoice"
    end

    test "updates invoice and returns to show", %{conn: conn, invoice: invoice} do
      {:ok, show_live, _html} = live(conn, ~p"/invoices/#{invoice}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/invoices/#{invoice}/edit?return_to=show")

      assert render(form_live) =~ "Edit Invoice"

      assert form_live
             |> form("#invoice-form", invoice: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#invoice-form", invoice: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/invoices/#{invoice}")

      html = render(show_live)
      assert html =~ "Invoice updated successfully"
    end
  end
end
