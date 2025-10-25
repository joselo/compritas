defmodule BillingWeb.ElectronicInvoiceComponents do
  use Phoenix.Component
  use Gettext, backend: BillingWeb.Gettext

  alias Billing.Invoices.ElectronicInvoice

  def state(assigns) do
    assigns =
      assign_new(assigns, :state, fn ->
        if assigns.electronic_invoice do
          %{
            label: ElectronicInvoice.label_status(assigns.electronic_invoice.state),
            css_class: "badge-primary"
          }
        else
          %{label: "Not invoice yet", css_class: "badge-info"}
        end
      end)

    ~H"""
    <span class={["badge", @state.css_class]}>
      {@state.label}
    </span>
    """
  end
end
