# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Billing.Repo.insert!(%Billing.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Billing.Repo
alias Billing.Customers.Customer
alias Billing.Companies.Company
alias Billing.Certificates.Certificate
alias Billing.EmissionProfiles.EmissionProfile
alias Billing.Invoices.Invoice
alias Billing.Invoices
alias Billing.Certificates
alias Billing.Products.Product

identification_number = "1234567890"
sequence = 1
certificate_password = "fake-password"

customer =
  %Customer{
    full_name: "Sub Zero",
    email: "sub.zero@example.com",
    identification_number: "1234567890",
    identification_type: :cedula,
    address: "Arena",
    phone_number: "9999999999"
  }
  |> Repo.insert!()

company =
  %Company{
    identification_number: identification_number <> "001",
    address: "Quito - Ecuador",
    name: "Mi empresa"
  }
  |> Repo.insert!()

{:ok, certificate} =
  %Certificate{
    name: "Firma P12",
    file: "file.p12"
  }
  |> Repo.insert!()
  |> Certificates.update_certificate_password(certificate_password)

emission_profile =
  %EmissionProfile{
    company_id: company.id,
    certificate_id: certificate.id,
    name: "Punto de emision 1",
    sequence: sequence
  }
  |> Repo.insert!()

Enum.each(1..20, fn _ ->
  invoice =
    %Invoice{
      customer_id: customer.id,
      emission_profile_id: emission_profile.id,
      issued_at: Date.utc_today(),
      description: "Producto de prueba",
      due_date: Date.add(Date.utc_today(), 5),
      amount: Decimal.new("10.0"),
      tax_rate: Decimal.new("15.0"),
      payment_method: :cash
    }
    |> Repo.insert!()

  amount_with_tax = Invoices.calculate_amount_with_tax(invoice)
  Invoices.save_taxes(invoice, amount_with_tax)
end)

customer =
  %Product{
    name: "Mortal Kombat I",
    price: Decimal.new("5.0")
  }
  |> Repo.insert!()
