defmodule Billing.CertificatesTest do
  use Billing.DataCase

  alias Billing.Certificates

  describe "certificates" do
    alias Billing.Certificates.Certificate

    import Billing.AccountsFixtures, only: [user_scope_fixture: 0]
    import Billing.CertificatesFixtures

    @invalid_attrs %{file: nil, password: nil}

    test "list_certificates/0 returns all certificates" do
      scope = user_scope_fixture()
      certificate = certificate_fixture(scope)

      assert Certificates.list_certificates(scope) == [certificate]
    end

    test "get_certificate!/1 returns the certificate with given id" do
      scope = user_scope_fixture()
      certificate = certificate_fixture(scope)

      assert Certificates.get_certificate!(scope, certificate.id) == certificate
    end

    test "create_certificate/1 with valid data creates a certificate" do
      scope = user_scope_fixture()

      valid_attrs = %{
        name: "some name",
        file: "some file",
        password: "some password"
      }

      assert {:ok, %Certificate{} = certificate} =
               Certificates.create_certificate(scope, valid_attrs)

      assert certificate.file == "some file"
      assert certificate.password == "some password"
    end

    test "create_certificate/1 with invalid data returns error changeset" do
      scope = user_scope_fixture()

      assert {:error, %Ecto.Changeset{}} = Certificates.create_certificate(scope, @invalid_attrs)
    end

    test "update_certificate/2 with valid data updates the certificate" do
      scope = user_scope_fixture()
      certificate = certificate_fixture(scope)
      update_attrs = %{file: "some updated file", password: "some updated password"}

      assert {:ok, %Certificate{} = certificate} =
               Certificates.update_certificate(scope, certificate, update_attrs)

      assert certificate.file == "some updated file"
      assert certificate.password == "some updated password"
    end

    test "update_certificate/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      certificate = certificate_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Certificates.update_certificate(scope, certificate, @invalid_attrs)

      assert certificate == Certificates.get_certificate!(scope, certificate.id)
    end

    test "delete_certificate/1 deletes the certificate" do
      scope = user_scope_fixture()
      certificate = certificate_fixture(scope)

      assert {:ok, %Certificate{}} = Certificates.delete_certificate(scope, certificate)

      assert_raise Ecto.NoResultsError, fn ->
        Certificates.get_certificate!(scope, certificate.id)
      end
    end

    test "change_certificate/1 returns a certificate changeset" do
      scope = user_scope_fixture()
      certificate = certificate_fixture(scope)

      assert %Ecto.Changeset{} = Certificates.change_certificate(scope, certificate)
    end
  end
end
