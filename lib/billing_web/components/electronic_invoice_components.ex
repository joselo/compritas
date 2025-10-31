defmodule BillingWeb.ElectronicInvoiceComponents do
  use Phoenix.Component
  use Gettext, backend: BillingWeb.Gettext

  alias Billing.Quotes.ElectronicInvoice

  @statuses_css_class %{
    created: "badge-primary",
    signed: "badge-info",
    sent: "badge-accent",
    back: "badge-secondary",
    authorized: "badge-success",
    unauthorized: "badge-warning",
    error: "badge-error",
    not_found_or_pending: "badge-primary"
  }

  attr :electronic_invoice, ElectronicInvoice, required: true

  def state(assigns) do
    assigns =
      assign_new(assigns, :state, fn ->
        %{
          label: ElectronicInvoice.label_status(assigns.electronic_invoice.state),
          css_class: @statuses_css_class[assigns.electronic_invoice.state]
        }
      end)

    ~H"""
    <span class={["badge", @state.css_class]}>
      {@state.label}
    </span>
    """
  end
end
