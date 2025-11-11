defmodule BillingWeb.EmissionProfileLiveTest do
  use BillingWeb.ConnCase

  import Phoenix.LiveViewTest
  import Billing.EmissionProfilesFixtures
  import Billing.CertificatesFixtures
  import Billing.CompaniesFixtures

  @create_attrs %{name: "some name", sequence: 1}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_user

  defp create_emission_profile(%{scope: scope}) do
    emission_profile = emission_profile_fixture(scope)

    %{emission_profile: emission_profile}
  end

  setup %{scope: scope} do
    certificate = certificate_fixture(scope)
    company = company_fixture(scope)

    %{certificate: certificate, company: company}
  end

  describe "Index" do
    setup [:create_emission_profile]

    test "lists all emission_profiles", %{conn: conn, emission_profile: emission_profile} do
      {:ok, _index_live, html} = live(conn, ~p"/emission_profiles")

      assert html =~ "Emission profiles"
      assert html =~ emission_profile.name
    end

    test "saves new emission_profile", %{conn: conn, certificate: certificate, company: company} do
      {:ok, index_live, _html} = live(conn, ~p"/emission_profiles")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Emission profile")
               |> render_click()
               |> follow_redirect(conn, ~p"/emission_profiles/new")

      assert render(form_live) =~ "New Emission profile"

      assert form_live
             |> form("#emission_profile-form", emission_profile: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      attrs =
        @create_attrs
        |> Map.put(:company_id, company.id)
        |> Map.put(:certificate_id, certificate.id)

      assert {:ok, index_live, _html} =
               form_live
               |> form("#emission_profile-form", emission_profile: attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/emission_profiles")

      html = render(index_live)
      assert html =~ "Emission profile created successfully"
      assert html =~ "some name"
    end

    test "updates emission_profile in listing", %{conn: conn, emission_profile: emission_profile} do
      {:ok, index_live, _html} = live(conn, ~p"/emission_profiles")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#emission_profiles-#{emission_profile.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/emission_profiles/#{emission_profile}/edit")

      assert render(form_live) =~ "Edit Emission profile"

      assert form_live
             |> form("#emission_profile-form", emission_profile: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#emission_profile-form", emission_profile: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/emission_profiles")

      html = render(index_live)
      assert html =~ "Emission profile updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes emission_profile in listing", %{conn: conn, emission_profile: emission_profile} do
      {:ok, index_live, _html} = live(conn, ~p"/emission_profiles")

      assert index_live
             |> element("#emission_profiles-#{emission_profile.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#emission_profiles-#{emission_profile.id}")
    end
  end

  describe "Show" do
    setup [:create_emission_profile]

    test "displays emission_profile", %{conn: conn, emission_profile: emission_profile} do
      {:ok, _show_live, html} = live(conn, ~p"/emission_profiles/#{emission_profile}")

      assert html =~ "Emission profile ##{emission_profile.id}"
      assert html =~ emission_profile.name
    end

    test "updates emission_profile and returns to show", %{
      conn: conn,
      emission_profile: emission_profile
    } do
      {:ok, show_live, _html} = live(conn, ~p"/emission_profiles/#{emission_profile}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(
                 conn,
                 ~p"/emission_profiles/#{emission_profile}/edit?return_to=show"
               )

      assert render(form_live) =~ "Edit Emission profile"

      assert form_live
             |> form("#emission_profile-form", emission_profile: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#emission_profile-form", emission_profile: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/emission_profiles/#{emission_profile}")

      html = render(show_live)
      assert html =~ "Emission profile updated successfully"
      assert html =~ "some updated name"
    end
  end
end
