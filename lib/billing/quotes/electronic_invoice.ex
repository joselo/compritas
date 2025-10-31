defmodule Billing.Quotes.ElectronicInvoice do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [
    :created,
    :signed,
    :sent,
    :back,
    :authorized,
    :unauthorized,
    :error,
    :not_found_or_pending
  ]

  @sri_statuses %{
    "RECIBIDA" => :sent,
    "DEVUELTA" => :back,
    "AUTORIZADO" => :authorized,
    "NO AUTORIZADO" => :unauthorized,
    "ERROR" => :error,
    "NO ENCONTRADO O PENDIENTE" => :not_found_or_pending
  }

  @label_statuses %{
    created: "Pendiente",
    signed: "Firmada",
    sent: "Enviada",
    back: "Devuelta",
    authorized: "Autorizada",
    unauthorized: "No Autorizada",
    error: "Error",
    not_found_or_pending: "No encontrada o pendiente"
  }

  schema "electronic_invoices" do
    belongs_to :quote, Billing.Quotes.Quote

    field :access_key, :string
    field :state, Ecto.Enum, values: @statuses, default: :created

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(electronic_invoice, attrs) do
    electronic_invoice
    |> cast(attrs, [
      :quote_id,
      :access_key,
      :state
    ])
    |> validate_required([
      :quote_id,
      :access_key,
      :state
    ])
  end

  def determinate_status(sri_status) do
    @sri_statuses[sri_status]
  end

  def label_status(state) do
    @label_statuses[state]
  end

  def allow_send(current_state) do
    current_state == :signed
  end

  def allow_verify_authorization(current_state) do
    current_state == :not_found_or_pending
  end

  def authorized?(current_state) do
    current_state == :authorized
  end
end
