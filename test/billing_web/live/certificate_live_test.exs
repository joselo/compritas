defmodule BillingWeb.CertificateLiveTest do
  use BillingWeb.ConnCase

  import Phoenix.LiveViewTest
  import Billing.CertificatesFixtures
  import Billing.AccountsFixtures

  @create_attrs %{
    name: "My P12 file",
    password: "fake-password"
  }

  @update_attrs %{
    name: "Signature P12",
    password: "password-updated"
  }

  @invalid_attrs %{name: nil}
  defp create_certificate(_) do
    certificate = certificate_fixture()

    %{certificate: certificate}
  end

  setup %{conn: conn} do
    file_path = "./test/support/fixtures/fake-p12-file.p12"
    file_content = File.read!(file_path)
    %{size: file_size} = File.stat!(file_path)

    certificate_file =
      %{
        last_modified: 1_594_171_879_000,
        name: "file.p12",
        content: file_content,
        size: file_size,
        type: "application/x-pkcs12"
      }

    user = user_fixture()

    %{conn: log_in_user(conn, user), certificate_file: certificate_file}
  end

  describe "Index" do
    setup [:create_certificate]

    test "lists all certificates", %{conn: conn, certificate: certificate} do
      {:ok, _index_live, html} = live(conn, ~p"/certificates")

      assert html =~ "Listing Certificates"
      assert html =~ certificate.file
    end

    test "saves new certificate", %{conn: conn, certificate_file: certificate_file} do
      {:ok, index_live, _html} = live(conn, ~p"/certificates")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Certificate")
               |> render_click()
               |> follow_redirect(conn, ~p"/certificates/new")

      assert render(form_live) =~ "New Certificate"

      assert form_live
             |> form("#certificate-form", certificate: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      file = file_input(form_live, "#certificate-form", :certificate_file, [certificate_file])

      assert render_upload(file, "file.p12") =~ "100%"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#certificate-form", certificate: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/certificates")

      html = render(index_live)
      assert html =~ "Certificate created successfully"
      assert html =~ "file.p12"
    end

    test "updates certificate in listing", %{conn: conn, certificate: certificate} do
      {:ok, index_live, _html} = live(conn, ~p"/certificates")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#certificates-#{certificate.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/certificates/#{certificate}/edit")

      assert render(form_live) =~ "Edit Certificate"

      assert form_live
             |> form("#certificate-form", certificate: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#certificate-form", certificate: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/certificates")

      html = render(index_live)
      assert html =~ "Certificate updated successfully"
      assert html =~ "Signature P12"
    end

    test "deletes certificate in listing", %{conn: conn, certificate: certificate} do
      {:ok, index_live, _html} = live(conn, ~p"/certificates")

      assert index_live
             |> element("#certificates-#{certificate.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#certificates-#{certificate.id}")
    end
  end

  describe "Show" do
    setup [:create_certificate]

    test "displays certificate", %{conn: conn, certificate: certificate} do
      {:ok, _show_live, html} = live(conn, ~p"/certificates/#{certificate}")

      assert html =~ "Show Certificate"
      assert html =~ certificate.file
    end

    test "updates certificate and returns to show", %{conn: conn, certificate: certificate} do
      {:ok, show_live, _html} = live(conn, ~p"/certificates/#{certificate}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/certificates/#{certificate}/edit?return_to=show")

      assert render(form_live) =~ "Edit Certificate"

      assert form_live
             |> form("#certificate-form", certificate: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#certificate-form", certificate: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/certificates/#{certificate}")

      html = render(show_live)
      assert html =~ "Certificate updated successfully"
      assert html =~ "Signature P12"
    end
  end
end
