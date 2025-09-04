defmodule Billing.InvoicingTest do
  use Billing.DataCase

  import Billing.InvoicesFixtures
  import Billing.CustomersFixtures
  import Billing.EmissionProfilesFixtures
  import Billing.CompaniesFixtures
  import Billing.CertificatesFixtures

  setup do
    customer =
      customer_fixture(%{
        full_name: "John Doe",
        email: "john@example.com",
        identification_number: "123456789",
        identification_type: "cedula",
        address: "123 Main St",
        phone_number: "1234567890"
      })

    company =
      company_fixture(%{
        identification_number: "987654321",
        address: "456 Elm St",
        name: "Example Company"
      })

    certificate =
      certificate_fixture(%{
        name: "Certificate Name",
        file: "certificate_file.p12",
        password: "certificate_password"
      })

    emission_profile =
      emission_profile_fixture(%{
        company_id: company.id,
        certificate_id: certificate.id,
        name: "Emission Profile Name"
      })

    invoice =
      invoice_fixture(%{
        customer_id: customer.id,
        emission_profile_id: emission_profile.id,
        issued_at: DateTime.utc_now(),
        description: "Invoice Description",
        due_date: DateTime.add(DateTime.utc_now(), 30, :day),
        amount: 100.0,
        tax_rate: 15.0,
        payment_method: "credit_card"
      })

    amount_with_tax = Billing.Invoices.calculate_amount_with_tax(invoice)
    Billing.Invoices.save_taxes(invoice, amount_with_tax)

    {:ok, invoice: invoice}
  end

  describe "build_request_params" do
    test "creates invoice request params", %{invoice: invoice} do
      params = Billing.Invoicing.build_request_params(invoice)

      IO.inspect(params)

      # assert params["customer_id"] == invoice.customer_id
      # assert params["amount"] == invoice.amount
    end
  end
end
